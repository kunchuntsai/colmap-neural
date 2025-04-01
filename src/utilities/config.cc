#include "config.h"
#include "logger.h"
#include <fstream>
#include <sstream>
#include <iostream>
#include <algorithm>

// Trim function
static inline std::string trim(const std::string &s) {
    auto wsfront = std::find_if_not(s.begin(), s.end(), [](int c){return std::isspace(c);});
    auto wsback = std::find_if_not(s.rbegin(), s.rend(), [](int c){return std::isspace(c);}).base();
    return (wsback <= wsfront ? std::string() : std::string(wsfront, wsback));
}

// New function to remove comments
static inline std::string removeComment(const std::string &s) {
    size_t pos = s.find(';');
    if (pos != std::string::npos) {
        return s.substr(0, pos);
    }
    return s;
}

bool Config::loadFromFile(const std::string& filename) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Failed to open config file: " << filename << std::endl;
        return false;
    }

    std::string line;
    std::string section;

    bool sourceSpecified = false;
    bool videoPathSpecified = false;

    // Set default log level mask
    logLevelMask = LOG_LV_ERROR | LOG_LV_WARNING | LOG_LV_INFO;

    while (std::getline(file, line)) {
        // Skip empty lines and pure comment lines
        if (line.empty() || line[0] == ';' || line[0] == '#') {
            continue;
        }

        // Check for section header
        if (line[0] == '[' && line[line.size() - 1] == ']') {
            section = line.substr(1, line.size() - 2);
            continue;
        }

        // Parse key-value pairs
        std::istringstream is_line(line);
        std::string key;
        if (std::getline(is_line, key, '=')) {
            std::string value;
            if (std::getline(is_line, value)) {
                key = trim(key);
                value = trim(removeComment(value));

                if (section == "Model") {
                    if (key == "path") {
                        if (value.length() >= 5 && value.substr(value.length() - 5) == ".onnx") {
                            modelPath = value;
                        } else {
                            std::cerr << "Invalid model path: File must have .onnx extension" << std::endl;
                            return false;
                        }
                    }
                    else if (key == "confidence_threshold") confidenceThreshold = std::stof(value);
                } else if (section == "Input") {
                    if (key == "source") {
                        sourceSpecified = true;
                        std::string lowerValue = value;
                        std::transform(lowerValue.begin(), lowerValue.end(), lowerValue.begin(),
                                    [](unsigned char c){ return std::tolower(c); });
                        if (lowerValue == "camera") {
                            inputSource = InputSource::CAMERA;
                        } else if (lowerValue == "video") {
                            inputSource = InputSource::VIDEO;
                        } else {
                            std::cerr << "Invalid input source: '" << value << "'. Using default (VIDEO)." << std::endl;
                            inputSource = InputSource::VIDEO;
                        }
                    } else if (key == "video_path") {
                        videoPath = value;
                        videoPathSpecified = !videoPath.empty();
                    }
                } else if (section == "Tracking") {
                    if (key == "iou_threshold") iouThreshold = std::stof(value);
                    else if (key == "max_frames_to_skip") maxFramesToSkip = std::stoi(value);
                } else if (section == "Logging") {
                    if (key == "debug") {
                        std::string lowerValue = value;
                        std::transform(lowerValue.begin(), lowerValue.end(), lowerValue.begin(),
                                    [](unsigned char c){ return std::tolower(c); });
                        if (lowerValue == "true" || lowerValue == "1" || lowerValue == "yes") {
                            logLevelMask |= LOG_LV_DEBUG;
                        } else {
                            logLevelMask &= ~LOG_LV_DEBUG;
                        }
                    }
                } else if (section == "Colmap") {
                    if (key == "image_path") {
                        colmapImagePath = value;
                    } else if (key == "output_path") {
                        colmapOutputPath = value;
                    } else if (key == "dense") {
                        std::string lowerValue = value;
                        std::transform(lowerValue.begin(), lowerValue.end(), lowerValue.begin(),
                                    [](unsigned char c){ return std::tolower(c); });
                        colmapDenseEnabled = (lowerValue == "true" || lowerValue == "1" || lowerValue == "yes");
                    } else if (key == "data_type") {
                        std::string lowerValue = value;
                        std::transform(lowerValue.begin(), lowerValue.end(), lowerValue.begin(),
                                    [](unsigned char c){ return std::tolower(c); });
                        
                        if (lowerValue == "video") {
                            colmapDataType = colmap::AutomaticReconstructionController::DataType::VIDEO;
                        } else if (lowerValue == "image") {
                            colmapDataType = colmap::AutomaticReconstructionController::DataType::INDIVIDUAL;
                        } else if (lowerValue == "individual") {
                            colmapDataType = colmap::AutomaticReconstructionController::DataType::INDIVIDUAL;
                        } else {
                            std::cerr << "Invalid COLMAP data type: '" << value << "'. Using default (INDIVIDUAL)." << std::endl;
                        }
                    } else if (key == "quality") {
                        std::string lowerValue = value;
                        std::transform(lowerValue.begin(), lowerValue.end(), lowerValue.begin(),
                                    [](unsigned char c){ return std::tolower(c); });
                        
                        if (lowerValue == "low") {
                            colmapQuality = colmap::AutomaticReconstructionController::Quality::LOW;
                        } else if (lowerValue == "medium") {
                            colmapQuality = colmap::AutomaticReconstructionController::Quality::MEDIUM;
                        } else if (lowerValue == "high") {
                            colmapQuality = colmap::AutomaticReconstructionController::Quality::HIGH;
                        } else if (lowerValue == "extreme") {
                            colmapQuality = colmap::AutomaticReconstructionController::Quality::EXTREME;
                        } else {
                            std::cerr << "Invalid COLMAP quality setting: '" << value << "'. Using default (HIGH)." << std::endl;
                        }
                    }
                }
            }
        }
    } //while()

    // Validate input configuration
    if (!sourceSpecified) {
        if (videoPathSpecified) {
            std::cerr << "Input source not specified. Using default (VIDEO) because video path is present." << std::endl;
            inputSource = InputSource::VIDEO;
        } else {
            std::cerr << "Invalid configuration: Neither input source nor video path specified." << std::endl;
            return false;
        }
    }

    if (inputSource == InputSource::VIDEO && !videoPathSpecified) {
        std::cerr << "Invalid configuration: Video source selected but no valid video path provided." << std::endl;
        return false;
    }

    if (inputSource == InputSource::CAMERA && videoPathSpecified) {
        std::cerr << "Camera input selected but video path also specified. Video path will be ignored." << std::endl;
        videoPath = "";
    }

    return true;
}
/**
 * @file config.h
 * @brief Configuration class for managing application settings
 */

#pragma once

#include <string>
#include <colmap/controllers/automatic_reconstruction.h>

/**
 * @class Config
 * @brief Manages configuration settings for the application
 */
class Config {
public:
    /**
     * @enum InputSource
     * @brief Specifies the source of input for the application
     */
    enum class InputSource {
        VIDEO,  /**< Input from a video file */
        CAMERA  /**< Input from a camera */
    };

    /**
     * @brief Loads configuration from a file
     * @param filename The path to the configuration file
     * @return true if loading was successful, false otherwise
     */
    static bool loadFromFile(const std::string& filename);

    /**
     * @brief Sets the input source
     * @param source The input source to set
     */
    static void setInputSource(InputSource source) {
        inputSource = source;
    }

    /**
     * @brief Gets the current input source
     * @return The current input source
     */
    static InputSource getInputSource() {
        return inputSource;
    }

    /**
     * @brief Sets the path to the video file
     * @param path The path to the video file
     */
    static void setVideoPath(const std::string& path) {
        videoPath = path;
    }

    /**
     * @brief Gets the path to the video file
     * @return The path to the video file
     */
    static std::string getVideoPath() {
        return videoPath;
    }

    /**
     * @brief Gets the path to the model file
     * @return The path to the model file
     */
    static std::string getModelPath() { return modelPath; }

    /**
     * @brief Gets the confidence threshold
     * @return The confidence threshold
     */
    static float getConfidenceThreshold() { return confidenceThreshold; }

    /**
     * @brief Gets the IoU threshold
     * @return The IoU threshold
     */
    static float getIoUThreshold() { return iouThreshold; }

    /**
     * @brief Gets the maximum number of frames to skip
     * @return The maximum number of frames to skip
     */
    static int getMaxFramesToSkip() { return maxFramesToSkip; }

    /**
     * @brief Gets the log level mask
     * @return The log level mask
     */
    static int getLogLevelMask() { return logLevelMask; }

    /**
     * @brief Gets the COLMAP image path
     * @return The COLMAP image path
     */
    static std::string getColmapImagePath() { return colmapImagePath; }

    /**
     * @brief Sets the COLMAP image path
     * @param path The path to set
     */
    static void setColmapImagePath(const std::string& path) {
        colmapImagePath = path;
    }

    /**
     * @brief Gets the COLMAP output path
     * @return The COLMAP output path
     */
    static std::string getColmapOutputPath() { return colmapOutputPath; }

    /**
     * @brief Sets the COLMAP output path
     * @param path The path to set
     */
    static void setColmapOutputPath(const std::string& path) {
        colmapOutputPath = path;
    }

    /**
     * @brief Gets whether COLMAP dense reconstruction is enabled
     * @return true if dense reconstruction is enabled, false otherwise
     */
    static bool getColmapDenseEnabled() { return colmapDenseEnabled; }

    /**
     * @brief Gets the COLMAP data type
     * @return The COLMAP data type
     */
    static colmap::AutomaticReconstructionController::DataType getColmapDataType() { 
        return colmapDataType; 
    }

    /**
     * @brief Gets the COLMAP quality setting
     * @return The COLMAP quality setting
     */
    static colmap::AutomaticReconstructionController::Quality getColmapQuality() { 
        return colmapQuality; 
    }

private:
    static inline InputSource inputSource = InputSource::VIDEO;
    static inline std::string videoPath = "";
    static inline std::string modelPath = "";
    static inline float confidenceThreshold = 0.5f;
    static inline float iouThreshold = 0.5f;
    static inline int maxFramesToSkip = 10;
    static inline int logLevelMask = 0;

    // COLMAP specific settings
    static inline std::string colmapImagePath = "";
    static inline std::string colmapOutputPath = "";
    static inline bool colmapDenseEnabled = true;
    static inline colmap::AutomaticReconstructionController::DataType colmapDataType = 
        colmap::AutomaticReconstructionController::DataType::INDIVIDUAL;
    static inline colmap::AutomaticReconstructionController::Quality colmapQuality = 
        colmap::AutomaticReconstructionController::Quality::HIGH;
};
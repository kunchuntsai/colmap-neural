#include <colmap/controllers/automatic_reconstruction.h>
#include <colmap/controllers/option_manager.h>
#include <colmap/util/misc.h>
#include <colmap/util/logging.h>
#include <colmap/base/database.h>
#include <colmap/feature/extraction.h>
#include <colmap/feature/matching.h>

#include <iostream>
#include <memory>

#include "config.h"
#include "frame_source.h"
#include "logger.h"

/**
 * Usage: ./colmap-neural-app <path_to_config_file>
 */
int main(int argc, char** argv) {
    
    if (argc < 2) {
        LOG_ERROR("Usage: %s <path_to_config_file>", argv[0]);
        return 1;
    }

    std::string configPath = argv[1];

    // 1. read config file
    if (!Config::loadFromFile(configPath)) {
        LOG_ERROR("Failed to load configuration file: %s", configPath.c_str());
        return 1;
    }
    
    // 2. setup logger - using our custom logger.h (better integration with Config)
    // Set log level from config
    Logger::getInstance().setLogLevel(Config::getLogLevelMask());
    LOG_INFO("Logger initialized with level mask: %d", Config::getLogLevelMask());

    // 3. initialize frame source
    FrameSource& frameSource = FrameSource::getInstance();
    if (!frameSource.initialize()) {
        LOG_ERROR("Failed to initialize frame source");
        return 1;
    }
    LOG_INFO("Frame source initialized successfully");

    // 4. Create the output directories if they don't exist for colmap results
    std::string outputPath = Config::getColmapOutputPath();
    if (outputPath.empty()) {
        LOG_ERROR("Output path not specified in config file.");
        return 1;
    }
    
    if (!colmap::CreateDirIfNotExists(outputPath)) {
        LOG_ERROR("Failed to create output directory: %s", outputPath.c_str());
        return 1;
    }
    LOG_INFO("Output directory created/verified: %s", outputPath.c_str());

    // 5. Configure colmap parameters
    colmap::AutomaticReconstructionController::Options options;
    
    // Set image path
    std::string imagePath = Config::getColmapImagePath();
    if (imagePath.empty()) {
        LOG_ERROR("Image path not specified in config file.");
        return 1;
    }
    options.image_path = imagePath;
    
    options.workspace_path = outputPath;
    options.data_type = Config::getColmapDataType();
    options.quality = Config::getColmapQuality();
    options.dense = Config::getColmapDenseEnabled();
    
    // Create database path within the output directory
    options.database_path = colmap::JoinPaths(outputPath, "database.db");
    
    LOG_INFO("COLMAP configuration:");
    LOG_INFO("  Image path: %s", options.image_path.c_str());
    LOG_INFO("  Workspace path: %s", options.workspace_path.c_str());
    LOG_INFO("  Database path: %s", options.database_path.c_str());
    LOG_INFO("  Dense reconstruction: %s", options.dense ? "Enabled" : "Disabled");
    
    // Initialize the reconstruction controller
    colmap::AutomaticReconstructionController reconstruction(options,
                                                          colmap::ReconstructionManager());
    
    // 6. Start the reconstruction process
    LOG_INFO("Starting reconstruction...");
    reconstruction.Start();
    reconstruction.Wait();
    
    LOG_INFO("Reconstruction completed successfully.");
    
    return EXIT_SUCCESS;
}
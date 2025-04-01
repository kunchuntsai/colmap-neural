/**
 * main.cpp - COLMAP Neural Application Entry Point
 * 
 * This file serves as the main entry point for the enhanced COLMAP application
 * that integrates neural network components for improved feature extraction,
 * matching, and dense reconstruction optimized for Apple M4 Pro.
 */

#include <iostream>
#include <string>
#include <memory>
#include <filesystem>

#include <gflags/gflags.h>
#include <glog/logging.h>

#include "colmap/util/misc.h"
#include "colmap/util/option_manager.h"
#include "colmap/controllers/automatic_reconstruction.h"

#include "neural-extensions/neural-core/include/neural_interface.h"

// Define command-line arguments
DEFINE_string(project_path, "", "Path to the project folder");
DEFINE_string(image_path, "", "Path to the folder containing images");
DEFINE_bool(use_neural, true, "Use neural network components");
DEFINE_bool(use_gpu, true, "Use GPU acceleration (Metal on Apple M4)");
DEFINE_int32(num_threads, -1, "Number of threads to use (-1 for auto)");

int main(int argc, char** argv) {
    // Initialize Google's logging library
    google::InitGoogleLogging(argv[0]);
    gflags::ParseCommandLineFlags(&argc, &argv, true);
    
    // Print program banner
    std::cout << "COLMAP Neural - Enhanced Structure-from-Motion" << std::endl;
    std::cout << "=======================================" << std::endl;
    std::cout << "Optimized for Apple M4 Pro with Metal" << std::endl;
    std::cout << std::endl;
    
    // Validate command-line arguments
    if (FLAGS_project_path.empty()) {
        std::cerr << "Error: --project_path is required" << std::endl;
        return EXIT_FAILURE;
    }
    
    if (FLAGS_image_path.empty()) {
        std::cerr << "Error: --image_path is required" << std::endl;
        return EXIT_FAILURE;
    }
    
    // Create project directory if it doesn't exist
    if (!std::filesystem::exists(FLAGS_project_path)) {
        std::filesystem::create_directories(FLAGS_project_path);
        std::cout << "Created project directory: " << FLAGS_project_path << std::endl;
    }
    
    // Set number of threads if automatic
    if (FLAGS_num_threads <= 0) {
        FLAGS_num_threads = std::thread::hardware_concurrency();
        std::cout << "Using " << FLAGS_num_threads << " threads (automatic)" << std::endl;
    }
    
    try {
        // Initialize COLMAP option manager
        colmap::OptionManager options;
        options.AddAutomaticReconstructionOptions();
        
        // Configure reconstruction options
        auto& reconstruction_options = options.automatic_reconstruction_options;
        reconstruction_options.image_path = FLAGS_image_path;
        reconstruction_options.workspace_path = FLAGS_project_path;
        reconstruction_options.num_threads = FLAGS_num_threads;
        reconstruction_options.use_gpu = FLAGS_use_gpu;
        
        // Initialize neural interface if required
        std::unique_ptr<NeuralInterface> neural_interface;
        if (FLAGS_use_neural) {
            std::cout << "Initializing neural network components..." << std::endl;
            neural_interface = std::make_unique<NeuralInterface>();
            
            // Configure neural components
            neural_interface->ConfigureForReconstruction(options);
            std::cout << "Neural components initialized successfully" << std::endl;
        } else {
            std::cout << "Using standard COLMAP pipeline (neural components disabled)" << std::endl;
        }
        
        // Start the reconstruction process
        std::cout << "Starting reconstruction..." << std::endl;
        
        if (FLAGS_use_neural && neural_interface) {
            // Use neural-enhanced reconstruction
            neural_interface->RunReconstruction(options);
        } else {
            // Use standard COLMAP reconstruction
            colmap::AutomaticReconstructionController controller(options);
            controller.Start();
            controller.Wait();
        }
        
        std::cout << "Reconstruction completed successfully" << std::endl;
        return EXIT_SUCCESS;
        
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return EXIT_FAILURE;
    }
}
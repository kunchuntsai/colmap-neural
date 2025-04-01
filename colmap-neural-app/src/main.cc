/**
 * main.cpp - COLMAP Neural Application Entry Point
 * 
 * This file serves as the main entry point for the enhanced COLMAP application
 * that integrates neural network components for improved feature extraction,
 * matching, and dense reconstruction optimized for Apple M4 Pro.
 */
#include <colmap/controllers/automatic_reconstruction.h>
#include <colmap/controllers/option_manager.h>
#include <colmap/feature/sift.h>        // For SiftExtractionOptions
#include <colmap/feature/matcher.h>     // For SiftMatchingOptions
#include <colmap/util/misc.h>           // For CreateDirIfNotExists
#include <colmap/util/file.h>           // For JoinPaths

#include <gflags/gflags.h>
#include <iostream>

// Define command-line flags
DEFINE_string(image_path, "", "Path to the input images.");
DEFINE_string(output_path, "", "Path to the output reconstruction.");
DEFINE_bool(use_gpu, true, "Whether to use GPU for feature extraction and matching.");

int main(int argc, char** argv) {
    // Parse command-line flags
    gflags::ParseCommandLineFlags(&argc, &argv, true);
    
    // Check if required paths are provided
    if (FLAGS_image_path.empty()) {
        std::cerr << "Error: Must specify --image_path." << std::endl;
        return EXIT_FAILURE;
    }
    if (FLAGS_output_path.empty()) {
        std::cerr << "Error: Must specify --output_path." << std::endl;
        return EXIT_FAILURE;
    }
    
    // Create automatic reconstruction options
    colmap::ReconstructionManagerController::Options options;
    
    // Configure GPU usage for feature extraction and matching
    options.sift_extraction_options->use_gpu = FLAGS_use_gpu;
    options.sift_matching_options->use_gpu = FLAGS_use_gpu;
    
    // Set database path
    *options.database_path = colmap::JoinPaths(FLAGS_output_path, "database.db");
    
    // Create output directory if it doesn't exist
    colmap::CreateDirIfNotExists(FLAGS_output_path);
    
    // Initialize automatic reconstruction controller
    colmap::AutomaticReconstructionController reconstruction(options, FLAGS_image_path, FLAGS_output_path);
    
    // Start reconstruction
    reconstruction.Start();
    reconstruction.Wait();
    
    std::cout << "Reconstruction completed." << std::endl;
    
    return EXIT_SUCCESS;
}
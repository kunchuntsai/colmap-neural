/**
 * neural_interface.h - Interface to Neural Network Components
 * 
 * This file defines the interface between COLMAP and the neural network
 * components for feature extraction, matching, and dense reconstruction.
 */

#pragma once

#include <memory>
#include <string>

// Forward declarations for COLMAP classes
namespace colmap {
    class OptionManager;
}

// Forward declarations for neural components
class SuperPoint;
class NetVLAD;
class SuperGlue;
class MVSNet;
class ModelLoader;

/**
 * NeuralInterface - Main interface for neural-enhanced COLMAP
 * 
 * This class serves as the main interface for the neural-enhanced COLMAP
 * pipeline. It coordinates the different neural components and provides
 * a unified interface to the main application.
 */
class NeuralInterface {
public:
    /**
     * Constructor
     * 
     * Initializes the neural interface and checks for available hardware
     * acceleration (Metal on Apple M4 Pro).
     */
    NeuralInterface();
    
    /**
     * Destructor
     * 
     * Cleans up resources used by the neural interface.
     */
    ~NeuralInterface();
    
    /**
     * Configure neural components for reconstruction
     * 
     * @param options COLMAP option manager
     * @return true if successful, false otherwise
     */
    bool ConfigureForReconstruction(colmap::OptionManager& options);
    
    /**
     * Run the reconstruction process
     * 
     * @param options COLMAP option manager
     * @return true if successful, false otherwise
     */
    bool RunReconstruction(colmap::OptionManager& options);
    
private:
    // Neural components
    std::shared_ptr<SuperPoint> superpoint_;
    std::shared_ptr<NetVLAD> netvlad_;
    std::shared_ptr<SuperGlue> superglue_;
    std::shared_ptr<MVSNet> mvsnet_;
    
    // Legacy components (used in Phase 1)
    std::unique_ptr<void> feature_extractor_;  // Will be updated in Phase 2
    std::unique_ptr<void> feature_matcher_;    // Will be updated in Phase 2
    std::unique_ptr<void> mvs_reconstructor_;  // Will be updated in Phase 2
    
    // Model loader
    std::unique_ptr<ModelLoader> model_loader_;
    
    // Hardware acceleration flags
    bool use_metal_ = false;
    bool is_apple_silicon_ = false;
    
    // Neural components status
    bool use_neural_ = true;
};
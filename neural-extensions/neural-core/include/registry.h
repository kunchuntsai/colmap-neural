// neural-extensions/neural-core/include/registry.h
#pragma once

#include <string>
#include <memory>
#include <unordered_map>

namespace neural {

// Base class for all neural models
class NeuralModel {
public:
    virtual ~NeuralModel() = default;
    virtual bool Initialize(const std::string& model_path) = 0;
};

// Registry to manage neural models
class ModelRegistry {
public:
    static ModelRegistry& GetInstance();
    
    template <typename T>
    bool RegisterModel(const std::string& name);
    
    std::shared_ptr<NeuralModel> GetModel(const std::string& name);
    
private:
    ModelRegistry() = default;
    std::unordered_map<std::string, std::shared_ptr<NeuralModel>> models_;
};

// Interface initialization functions (to be implemented in Phase 2)
bool InitializeFeatureExtractors();
bool InitializeFeatureMatchers();  
bool InitializeDenseReconstruction();

} // namespace neural
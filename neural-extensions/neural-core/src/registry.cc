// neural-extensions/neural-core/src/registry.cc
#include "registry.h"
#include <iostream>

namespace neural {

ModelRegistry& ModelRegistry::GetInstance() {
    static ModelRegistry instance;
    return instance;
}

template <typename T>
bool ModelRegistry::RegisterModel(const std::string& name) {
    if (models_.find(name) != models_.end()) {
        std::cerr << "Model with name " << name << " already registered." << std::endl;
        return false;
    }
    
    models_[name] = std::make_shared<T>();
    return true;
}

std::shared_ptr<NeuralModel> ModelRegistry::GetModel(const std::string& name) {
    auto it = models_.find(name);
    if (it == models_.end()) {
        return nullptr;
    }
    return it->second;
}

// Placeholder implementations for Phase 1
bool InitializeFeatureExtractors() {
    std::cout << "Neural feature extractors would be initialized here in Phase 2" << std::endl;
    return true;
}

bool InitializeFeatureMatchers() {
    std::cout << "Neural feature matchers would be initialized here in Phase 2" << std::endl;
    return true;
}

bool InitializeDenseReconstruction() {
    std::cout << "Neural MVS components would be initialized here in Phase 2" << std::endl;
    return true;
}

} // namespace neural
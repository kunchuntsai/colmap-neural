#pragma once

#include <functional>
#include <memory>
#include <string>
#include <unordered_map>

// Forward declarations for COLMAP classes
namespace colmap {
class FeatureExtractor;
class FeatureMatcher;
class MVSModel;
}

namespace colmap_neural {

// Registry template for different types of extensions
template <typename T>
class Registry {
public:
    using FactoryFunc = std::function<std::unique_ptr<T>()>;
    
    static Registry<T>& GetInstance() {
        static Registry<T> instance;
        return instance;
    }
    
    void Register(const std::string& name, FactoryFunc factory) {
        factories_[name] = std::move(factory);
    }
    
    std::unique_ptr<T> Create(const std::string& name) {
        auto it = factories_.find(name);
        if (it != factories_.end()) {
            return it->second();
        }
        return nullptr;
    }
    
    std::vector<std::string> GetRegisteredNames() const {
        std::vector<std::string> names;
        for (const auto& pair : factories_) {
            names.push_back(pair.first);
        }
        return names;
    }
    
private:
    Registry() = default;
    std::unordered_map<std::string, FactoryFunc> factories_;
};

// Specific registries
using FeatureExtractorRegistry = Registry<colmap::FeatureExtractor>;
using FeatureMatcherRegistry = Registry<colmap::FeatureMatcher>;
using MVSModelRegistry = Registry<colmap::MVSModel>;

// Helper macros for registration
#define REGISTER_FEATURE_EXTRACTOR(name, class_name) \
    static bool name##_registered = []() { \
        colmap_neural::FeatureExtractorRegistry::GetInstance().Register( \
            #name, []() { return std::make_unique<class_name>(); }); \
        return true; \
    }()

#define REGISTER_FEATURE_MATCHER(name, class_name) \
    static bool name##_registered = []() { \
        colmap_neural::FeatureMatcherRegistry::GetInstance().Register( \
            #name, []() { return std::make_unique<class_name>(); }); \
        return true; \
    }()

#define REGISTER_MVS_MODEL(name, class_name) \
    static bool name##_registered = []() { \
        colmap_neural::MVSModelRegistry::GetInstance().Register( \
            #name, []() { return std::make_unique<class_name>(); }); \
        return true; \
    }()

} // namespace colmap_neural

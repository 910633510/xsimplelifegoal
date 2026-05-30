# Vendor Artifacts

Run `scripts/build-llama-xcframework.sh` to clone `llama.cpp`, build `llama.xcframework`, and copy it into `Vendor/Frameworks/`.

The generated framework and cloned source are ignored by git. The app builds without the framework and reports `LocalLLMError.runtimeUnavailable`; when the framework is present and linked, `LocalLLMService` compiles the `canImport(llama)` path.

The project currently provides framework search paths as an integration boundary only. Real llama runtime work will need explicit link/embed settings once `llama.xcframework` is present.

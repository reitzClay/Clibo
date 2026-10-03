package com.claybytes.clibobe.dto;

public class AiPromptRequest {
    private String prompt;
    private String imageBase64;
    private String imageMimeType = "image/jpeg";
    private String audioBase64;
    private String audioMimeType = "audio/mp3";
    private String aiProvider; // "ollama", "gemini", "byok", "openai", "claude", "custom"
    private String ollamaBaseUrl;
    private String ollamaModel;
    private String byokApiKey;
    private String customBaseUrl;
    private String customModel;

    public AiPromptRequest() {
    }

    public AiPromptRequest(String prompt) {
        this.prompt = prompt;
    }

    public String getPrompt() {
        return prompt;
    }

    public void setPrompt(String prompt) {
        this.prompt = prompt;
    }

    public String getImageBase64() {
        return imageBase64;
    }

    public void setImageBase64(String imageBase64) {
        this.imageBase64 = imageBase64;
    }

    public String getImageMimeType() {
        return imageMimeType;
    }

    public void setImageMimeType(String imageMimeType) {
        this.imageMimeType = imageMimeType;
    }

    public String getAudioBase64() {
        return audioBase64;
    }

    public void setAudioBase64(String audioBase64) {
        this.audioBase64 = audioBase64;
    }

    public String getAudioMimeType() {
        return audioMimeType;
    }

    public void setAudioMimeType(String audioMimeType) {
        this.audioMimeType = audioMimeType;
    }

    public String getAiProvider() {
        return aiProvider;
    }

    public void setAiProvider(String aiProvider) {
        this.aiProvider = aiProvider;
    }

    public String getOllamaBaseUrl() {
        return ollamaBaseUrl;
    }

    public void setOllamaBaseUrl(String ollamaBaseUrl) {
        this.ollamaBaseUrl = ollamaBaseUrl;
    }

    public String getOllamaModel() {
        return ollamaModel;
    }

    public void setOllamaModel(String ollamaModel) {
        this.ollamaModel = ollamaModel;
    }

    public String getByokApiKey() {
        return byokApiKey;
    }

    public void setByokApiKey(String byokApiKey) {
        this.byokApiKey = byokApiKey;
    }

    public String getCustomBaseUrl() {
        return customBaseUrl;
    }

    public void setCustomBaseUrl(String customBaseUrl) {
        this.customBaseUrl = customBaseUrl;
    }

    public String getCustomModel() {
        return customModel;
    }

    public void setCustomModel(String customModel) {
        this.customModel = customModel;
    }
}

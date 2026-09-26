package com.claybytes.clibobe.dto;

import java.util.List;

// Main Request Wrapper
public record GeminiRequest(List<Content> contents) {}

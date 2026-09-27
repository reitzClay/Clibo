package com.claybytes.clibobe.dto;

public class Part {
    private String text;
    private InlineData inlineData;

    public Part() {
    }

    public Part(String text) {
        this.text = text;
    }

    public Part(String mimeType, String base64Data) {
        this.inlineData = new InlineData(mimeType, base64Data);
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }

    public InlineData getInlineData() {
        return inlineData;
    }

    public void setInlineData(InlineData inlineData) {
        this.inlineData = inlineData;
    }

    public static class InlineData {
        private String mimeType;
        private String data;

        public InlineData() {
        }

        public InlineData(String mimeType, String data) {
            this.mimeType = mimeType;
            this.data = data;
        }

        public String getMimeType() {
            return mimeType;
        }

        public void setMimeType(String mimeType) {
            this.mimeType = mimeType;
        }

        public String getData() {
            return data;
        }

        public void setData(String data) {
            this.data = data;
        }
    }
}

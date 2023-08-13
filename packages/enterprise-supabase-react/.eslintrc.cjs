module.exports = {
    root: true,
    extends: [
        "custom-react"
    ],
    parserOptions: {
        project: "./tsconfig.json",
    },
    settings: {
        react: {
            version: "detect"
        }
    },
    rules: {
        "@typescript-eslint/no-confusing-void-expression": "off",
        "@typescript-eslint/no-misused-promises": "off"
    }
};

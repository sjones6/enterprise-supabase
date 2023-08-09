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
        "@typescript-eslint/no-unsafe-assignment": "off",
        "@typescript-eslint/no-unsafe-member-access": "off"
    }
};

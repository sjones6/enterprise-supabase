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
        // "@typescript-eslint/no-unsafe-assignment": "off",
        // "@typescript-eslint/no-unsafe-member-access": "off",
        // "@typescript-eslint/no-unsafe-argument": "off",
        // "@typescript-eslint/no-unsafe-call": "off",
        // "@typescript-eslint/no-unsafe-return": "off",
        // "@typescript-eslint/no-unsafe-call": "off"
    }
};

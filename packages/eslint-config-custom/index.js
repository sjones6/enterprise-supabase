module.exports = {
  extends: ["turbo", "prettier", "eslint:recommended", "plugin:@typescript-eslint/strict-type-checked"],
  ignorePatterns: ["dist", ".eslintrc.cjs"],
  parser: "@typescript-eslint/parser",
};
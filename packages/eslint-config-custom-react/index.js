module.exports = {
  env: { browser: true, es2020: true },
  extends: [
    "custom",
    "plugin:react/recommended",
    "plugin:react-hooks/recommended",
  ],
  plugins: ["react-refresh"],
  rules: {
    "react-refresh/only-export-components": "off",
    "react/react-in-jsx-scope": "off",
    "react/prop-types": "off"
  },
};

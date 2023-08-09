module.exports = {
  root: true,
  extends: [
    "custom-react"
  ],
  parserOptions: {
    project: ["./tsconfig.json", "./tsconfig.node.json"],
  },
  settings: {
    react: {
        version: "detect"
    }
  }
};

module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
    "plugin:import/errors",
    "plugin:import/warnings",
    "plugin:import/typescript",
    "google",
    "plugin:@typescript-eslint/recommended",
  ],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: ["tsconfig.json", "tsconfig.dev.json"],
    sourceType: "module",
  },
  ignorePatterns: [
    "/lib/**/*", // Ignore built files.
    "/generated/**/*", // Ignore generated files.
  ],
  plugins: [
    "@typescript-eslint",
    "import",
  ],
  rules: {
    "quotes": ["off"],
    "import/no-unresolved": 0,
    "indent": ["off"],
    "max-len": ["off"],
    "no-trailing-spaces": ["off"],
    "object-curly-spacing": ["off"],
  },
  overrides: [
    {
      files: ["*.js"],
      rules: {
        // JavaScript-specific rules can be added here
      },
    },
  ],
};

function deriveDecodeOptions(options = {}) {
  const fastMode = options.fastMode === true;

  if (fastMode) {
    return {
      fastMode: true,
      workBudget: {
        decodeRounds: 1,
        foldRounds: 1,
        inlineRounds: 1,
      },
    };
  }

  return {
    fastMode: false,
    workBudget: {
      decodeRounds: 2,
      foldRounds: 3,
      inlineRounds: 3,
    },
  };
}

module.exports = {
  deriveDecodeOptions,
};

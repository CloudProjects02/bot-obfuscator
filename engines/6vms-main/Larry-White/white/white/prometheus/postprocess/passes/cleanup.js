function deriveCleanupOptions(options = {}) {
  const full = options.full === true;
  const fastMode = options.fastMode === true;

  if (full) {
    return {
      aggressiveCleanup: false,
      fastMode,
    };
  }

  if (fastMode) {
    return {
      aggressiveCleanup: false,
      fastMode: true,
    };
  }

  return {
    aggressiveCleanup: options.aggressiveCleanup === true,
    fastMode: false,
  };
}

module.exports = {
  deriveCleanupOptions,
};

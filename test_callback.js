const { useCallback } = require('react');

const mockUseCallback = (fn) => fn;

try {
  const tick = mockUseCallback(() => {
    console.log(tick);
  });
  tick();
} catch (e) {
  console.log("Error:", e.message);
}

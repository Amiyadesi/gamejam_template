# Prefer GL Compatibility for Web-first exports

This template targets browser jam builds first and Windows builds second, so it uses Godot 4.7 GL Compatibility on desktop and mobile instead of Forward+ or a D3D12 default. This trades advanced renderer features and peak desktop fidelity for WebGL support, closer shader behavior across targets, and one renderer to validate; games that require Forward+ should treat switching as a deliberate fork and retest shaders and exports.

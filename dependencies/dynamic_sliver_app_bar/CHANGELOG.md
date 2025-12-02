# Changelog

## [2.0.0] - 2024-12-02

### Added
- **AnimatedDynamicSliverAppBar**: New standalone widget with animation support
- Animation controller integration for smooth height transitions
- `OverflowBox` support during animations to allow natural content growth
- Continuous height measurement during animations (per-frame updates)
- `heightBuffer` parameter to prevent tiny overflow errors
- Comprehensive documentation and examples
- README with usage examples and tips

### Changed
- Improved height measurement accuracy with 1px buffer
- Better handling of animation state transitions
- More robust error handling for scroll controller access

### Technical Details
- Uses `SchedulerBinding.scheduleFrameCallback` for per-frame measurements
- `AnimatedBuilder` ensures proper widget rebuilds during animation
- Automatic switching between `OverflowBox` and normal `Container` based on animation state
- Height updates trigger `SliverAppBar`'s built-in animation for smooth transitions

## [1.0.0] - Previous

### Features
- Basic dynamic height calculation for `SliverAppBar`
- Automatic content measurement
- Standard `SliverAppBar` parameter support

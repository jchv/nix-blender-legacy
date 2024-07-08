{ callPackage, darwin, ... }:
{
  blender_2_83 = callPackage ./blender_2_83/default.nix {
    inherit (darwin.apple_sdk.frameworks)
      Cocoa
      CoreGraphics
      ForceFeedback
      OpenAL
      OpenGL
      ;
  };
}

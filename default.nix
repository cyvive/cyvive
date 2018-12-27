let
  pkgs = import <nixpkgs> {};

  devPkgs = with pkgs;
  [
    pkgs.git
    pkgs.nodejs-8_x
	];

	envPkgs = with pkgs;
	[
		pkgs.awscli
		pkgs.terraform
	];

	passthru = {
		env = false;
	};

in
  if pkgs.lib.inNixShell
	then
		rec {
			dev = pkgs.mkShell
				{ buildInputs = envPkgs ++ devPkgs; };
			prod = pkgs.mkShell
			{ buildInputs = envPkgs; };
		}
	else envPkgs


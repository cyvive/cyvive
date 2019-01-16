let
	pkgs = import <nixpkgs> {};
	#python = pkgs.python3.withPackages (ps: with ps; [ kube-shell ]);

	devPkgs = with pkgs;
  [
    pkgs.git
		pkgs.nodejs-8_x
		pkgs.which
	];

	envPkgs = with pkgs;
	[
		kubectl
		kube-prompt
		aws_shell
		python

		pkgs.terraform
	];

	# Create a project relative config directory for storing all external program information
	configPath = builtins.toPath (builtins.getEnv "PWD") + "/.nixconfig";
	# TODO enhance with direnv to allow multiple cluster / account selection(s)

	aws_shell = pkgs.symlinkJoin {
		name = "aws_shell";
		paths = [ pkgs.aws_shell ];
		buildInputs =	[ pkgs.makeWrapper ];
		postBuild = ''
			mkdir -p ${configPath}
			wrapProgram $out/bin/aws-shell \
				--set-default "AWS_CONFIG_FILE=${configPath}/aws-config AWS_SHARED_CREDENTIALS_FILE=${configPath}/aws-credentials"
		'';
	};

	kubectl = pkgs.symlinkJoin {
		name = "kubectl";
		paths = [ pkgs.kubectl ];
		buildInputs =	[ pkgs.makeWrapper ];
		postBuild = ''
			mkdir -p ${configPath}
			wrapProgram $out/bin/kubectl \
				--add-flags "--kubeconfig ${configPath}/kubectl"
		'';
	};

	kube-prompt = pkgs.symlinkJoin {
		name = "kube-prompt";
		paths = [ pkgs.kube-prompt ];
		buildInputs =	[ pkgs.makeWrapper ];
		postBuild = ''
			mkdir -p ${configPath}
			wrapProgram $out/bin/kube-prompt \
				--add-flags "--kubeconfig ${configPath}/kubectl"
		'';
	};

	ssh = pkgs.symlinkJoin {
		name = "ssh";
		paths = [ pkgs.openssh];
		buildInputs =	[ pkgs.makeWrapper ];
		postBuild = ''
			mkdir -p ${configPath}
			wrapProgram $out/bin/ssh \
				--add-flags "-i ${configPath}/ssh.pem"
		'';
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


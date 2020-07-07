// pin specific hashes; default would pull armv5/armel image.
local stretch20200607armv7 =
  'debian@sha256:6aac188bc15bac908192685068ef8512a2e51b5eb1138b663e9e33d1d98ade4b';
local buster20200607armv7 =
  'debian@sha256:43e8691b4e25f4b0fd0f10bca8ea11b9f0578b0e5d2fe3b085290455dd07c0b6';

local configs = {
  stretch: {
    amd64: 'debian:stretch-slim',
    arm64: 'debian:stretch-slim',
    arm: stretch20200607armv7,
  },
  buster: {
    amd64: 'debian:buster-slim',
    arm64: 'debian:buster-slim',
    arm: buster20200607armv7,
  },
  xenial: { amd64: 'ubuntu:xenial' },
  bionic: { amd64: 'ubuntu:bionic' },
  focal: { amd64: 'ubuntu:focal' },
};

[
  {
    local testImage = configs[distro][arch],

    kind: 'pipeline',
    type: 'docker',
    name: '%s/%s' % [distro, arch],

    platform: {
      os: 'linux',
      arch: arch,
    },

    steps: [{
      name: 'deb',
      image: 'arescentral/deb:%s' % distro,
      settings: { dir: distro },
    }, {
      name: 'check',
      image: testImage,
      commands: [
        'uname -a',
        'dpkg -i ninja-build_*.deb',
        'ninja --version',
      ],
    }, {
      name: 'publish',
      image: 'plugins/github-release',
      settings: {
        api_key: { from_secret: 'github_token' },
        files: [
          'ninja-build_*.deb',
          'ninja-build_*.dsc',
        ],
      },
      when: { event: 'tag' },
    }],
  }
  for distro in std.objectFields(configs)
  for arch in std.objectFields(configs[distro])
]

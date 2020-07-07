// pin specific hashes; default would pull armv5/armel image.
local stretch20200607armv7 =
  'debian@sha256:6aac188bc15bac908192685068ef8512a2e51b5eb1138b663e9e33d1d98ade4b';
local buster20200607armv7 =
  'debian@sha256:43e8691b4e25f4b0fd0f10bca8ea11b9f0578b0e5d2fe3b085290455dd07c0b6';

local configs = [{
  distro: 'debian',
  arch: 'amd64',
  versions: [
    { codename: 'buster', testImage: 'debian:buster-slim' },
    { codename: 'stretch', testImage: 'debian:stretch-slim' },
  ],
}, {
  distro: 'debian',
  arch: 'arm64',
  versions: [
    { codename: 'buster', testImage: 'debian:buster-slim' },
    { codename: 'stretch', testImage: 'debian:stretch-slim' },
  ],
}, {
  distro: 'debian',
  arch: 'arm',
  versions: [
    { codename: 'buster', testImage: buster20200607armv7 },
    { codename: 'stretch', testImage: stretch20200607armv7 },
  ],
}, {
  distro: 'ubuntu',
  arch: 'amd64',
  versions: [
    { codename: 'focal', testImage: 'ubuntu:focal' },
    { codename: 'bionic', testImage: 'ubuntu:bionic' },
    { codename: 'xenial', testImage: 'ubuntu:xenial' },
  ],
}];

[
  {
    local distro = config.distro,
    local arch = config.arch,
    local versions = config.versions,

    kind: 'pipeline',
    type: 'docker',
    name: '%s/%s' % [distro, arch],

    platform: {
      os: 'linux',
      arch: arch,
    },

    steps: std.flattenArrays([[{
      name: 'deb/%s' % version.codename,
      image: 'arescentral/deb:%s' % version.codename,
      settings: { dir: version.codename },
    }, {
      name: 'check/%s' % version.codename,
      image: version.testImage,
      commands: [
        'uname -a',
        'dpkg -i ninja-build_*.deb',
        'ninja --version',
      ],
    }] for version in versions]) + [{
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
  for config in configs
]

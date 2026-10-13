_ble_base_package_type=apt
function ble/base/package:apt/update {
  >&2 echo 'ble.sh is installed from deb.griffo.io. Update it with:'
  >&2 echo '  sudo apt update && sudo apt install --only-upgrade ble.sh'
  return 1
}

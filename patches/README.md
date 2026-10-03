# Common support is maintained as commits

The device depends on the modified sm8150-common nabu-los20 branch, including its optional shared tablet implementation. A small standalone patch no longer represents that implementation, so the old partial patch has been removed.

The upstream base remains recorded in upstream-lock.json. The required local common integration commit is recorded there separately. Build with the matching common checkout; publishing a reusable manifest should point at a fork containing that commit.

Complete before-change bundles are stored outside the source tree in /home/dengxh/android2/nabu-dt-backups/.

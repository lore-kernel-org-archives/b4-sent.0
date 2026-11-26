From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 26 Nov 2026 11:02:11 +0900
Subject: [PATCH v4 3/5] docs/system: Document zoned UFS logical units
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-zoned-ufs-v4b-v4-3-f90239d12a55@samsung.com>
References: <20261126-zoned-ufs-v4b-v4-0-f90239d12a55@samsung.com>
In-Reply-To: <20261126-zoned-ufs-v4b-v4-0-f90239d12a55@samsung.com>
To: qemu-devel@nongnu.org
Cc: Jeuk Kim <jeuk20.kim@samsung.com>, Paolo Bonzini <pbonzini@redhat.com>, 
 Fam Zheng <fam@euphon.net>, Kevin Wolf <kwolf@redhat.com>, 
 Hanna Reitz <hreitz@redhat.com>, qemu-block@nongnu.org, 
 Fabiano Rosas <farosas@suse.de>, Laurent Vivier <lvivier@redhat.com>, 
 Pierrick Bouvier <pierrick.bouvier@oss.qualcomm.com>, 
 Niklas Cassel <cassel@kernel.org>, Damien Le Moal <dlemoal@kernel.org>, 
 Sam Li <faithilikerun@gmail.com>, Stefan Hajnoczi <stefanha@redhat.com>, 
 Stanley Jhu <stanleyjhu@google.com>, 
 Keoseong Park <keosung.park@samsung.com>, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795658528; l=3191;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=E+FqxT7+4Rg8UwwbXL+CnxhEI7ZBRdGiOVMzAJRKTSo=;
 b=tVKKxaSWUqChu/m+uQMSxyL1IshBjxAB6yCHYHq5tbMWkUq2s7aXulMMV1L3KuVghO8iHx57C
 1gn0N+ZtgBnDpkShMJNkuXHlmYD+sNX9CELV4lySCOQuryTS0EtAKl5
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A logical unit on a host-managed zoned drive is going to be a zoned
logical unit. Document which drives qualify and what the guest sees.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 docs/system/devices/ufs.rst | 50 +++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 50 insertions(+)

diff --git a/docs/system/devices/ufs.rst b/docs/system/devices/ufs.rst
index 7e1fa671ab..0a33626b59 100644
--- a/docs/system/devices/ufs.rst
+++ b/docs/system/devices/ufs.rst
@@ -73,6 +73,56 @@ Logical Unit Properties
   Logical unit number, 0 to 31. A host controller accepts up to 32
   logical units.
 
+Zoned Logical Units
+===================
+
+A logical unit on a host-managed zoned drive is a zoned logical unit: a
+host-managed zoned block device (ZBC) with the zones of the drive. The
+drive is usually a qcow2 image created with the ``zone.*`` options. It
+must be writable, and its size and zone size must be multiples of the 4
+KiB logical block size. Every sequential zone must be writable to its
+end, since gap zones, with which ZBC describes a smaller capacity, are
+not modelled. ZBC cannot report an active zone limit, so the drive must
+have none below its number of sequential zones. A zoned host block
+device (``host_device``) reports zone errors of writes other than the
+zone resource errors as I/O errors, so the guest sees them as generic
+errors such as ABORTED COMMAND. A logical unit on a host-aware drive is
+a regular logical unit.
+
+The following creates an image with 64 MiB zones and adds a regular
+logical unit and a zoned one:
+
+.. code-block:: console
+
+    qemu-img create -f qcow2 lu1.qcow2 -o size=4G \
+        -o zone.mode=host-managed,zone.size=64M,zone.capacity=64M \
+        -o zone.max_open_zones=6
+
+    -drive file=lu0.img,if=none,id=lu0,format=raw \
+    -blockdev qcow2,node-name=lu1,file.driver=file,file.filename=lu1.qcow2 \
+    -device ufs,id=ufs0,serial=0001 \
+    -device ufs-lu,drive=lu0,bus=ufs0,lun=0 \
+    -device ufs-lu,drive=lu1,bus=ufs0,lun=1
+
+A Linux guest needs ``CONFIG_BLK_DEV_ZONED``. f2fs keeps its metadata on
+a regular logical unit, for example ``mkfs.f2fs -m -c /dev/sdb /dev/sda``
+with the zoned logical unit as ``/dev/sdb``, and needs at least as many
+open zones as its active logs, 6 by default.
+
+The zoned logical unit reports the ZBC device type in its INQUIRY data,
+the open zone limit of the image in the ZBC device characteristics VPD
+page, and RC BASIS 1 in READ CAPACITY(16). It handles REPORT ZONES and
+the OPEN, CLOSE, FINISH and RESET WRITE POINTER zone operations. A zone
+operation acts on one zone or, with the ALL bit, on every zone. A ZONE
+COUNT above 1 is rejected. Writes go to the image, which checks them
+against its zones. With ``detect-zeroes`` on, the image takes a write of
+zeros without moving the write pointer, so keep it off, the default. The
+logical unit does not support WRITE SAME. All other commands, including
+reads, MODE SENSE and SYNCHRONIZE CACHE, behave as on a regular logical
+unit.
+
+The image keeps the zones across restarts.
+
 Limitations
 ===========
 

-- 
2.43.0


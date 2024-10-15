From: Daniel Gomez <da.gomez@samsung.com>
Date: Tue, 15 Oct 2024 13:34:53 +0200
Subject: [PATCH 3/5] guestfs: bringup: fix unbound variable when debug
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241015-bringup-guestfs-debug-v1-3-bd74c0c31412@samsung.com>
References: <20241015-bringup-guestfs-debug-v1-0-bd74c0c31412@samsung.com>
In-Reply-To: <20241015-bringup-guestfs-debug-v1-0-bd74c0c31412@samsung.com>
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.com>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.15-dev-2a633
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728992109; l=2993;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=mFkyyCRh3HwHjMp/IgHLJ4cqQP62CHIqv6gemSsgnE8=;
 b=Jt/kkJEI6ktLXMUtu1kKbL9M140AoCagJnhw3VfAVlHEtiL2SxIuNt5E0To1Ol6iDoUWfLcY8
 1U59PJP/+2XDtAhD54ADhpDvO67zIckcSza95emHl4q/xeaLiSv9OQw
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix unbound variable errors. This is a silent error only found while
debugging. A variable may not be set, so check if set before comparing
the value to avoid 'unbound variable' error.

++ mktemp
+ cmdfile=/tmp/tmp.cn0hNYMZbt
+ '[' '!' -f /var/lib/libvirt/images/kdevops/guestfs/base_images/debian-12.raw ']'
.//scripts/bringup_guestfs.sh: line 289: CONFIG_GUESTFS_HAS_CUSTOM_RAW_IMAGE: unbound variable
make: *** [scripts/guestfs.Makefile:77: bringup_guestfs] Error 1

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 scripts/bringup_guestfs.sh | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/scripts/bringup_guestfs.sh b/scripts/bringup_guestfs.sh
index 5786975e48647321ecbc71ca9be6fb09c8aa63ff..19117e9a6ab55cfbe7c79f17e4a9b736edeb2607 100755
--- a/scripts/bringup_guestfs.sh
+++ b/scripts/bringup_guestfs.sh
@@ -242,7 +242,7 @@ _EOT
 	# For the life of me I can't get the following line to work with
 	# the virt-builder command and so we do a full edit of the file for now
 	# edit /etc/nsswitch.conf:'s/\[!UNAVAIL=return\]//'
-	if [[ "$CONFIG_GUESTFS_DEBIAN_TRIXIE" == "y" ]]; then
+	if [[ "${CONFIG_GUESTFS_DEBIAN_TRIXIE+x}" && "$CONFIG_GUESTFS_DEBIAN_TRIXIE" == "y" ]]; then
 		cat <<_EOT >>$cmdfile
 write /etc/nsswitch.conf: # kdevops generated /etc/nsswitch.conf
 append-line /etc/nsswitch.conf:passwd:         files
@@ -266,7 +266,7 @@ firstboot-command DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=tru
 firstboot-command systemctl stop ssh
 firstboot-command systemctl start ssh
 _EOT
-		if [[ "$CONFIG_GUESTFS_COPY_SOURCES_FROM_HOST_TO_GUEST" == "y" ]]; then
+		if [[ "${CONFIG_GUESTFS_COPY_SOURCES_FROM_HOST_TO_GUEST+x}" && "$CONFIG_GUESTFS_COPY_SOURCES_FROM_HOST_TO_GUEST" == "y" ]]; then
 		cat <<_EOT >>$cmdfile
 delete /etc/apt/sources.list.d/debian.sources
 _EOT
@@ -292,7 +292,7 @@ fi
 cmdfile=$(mktemp)
 
 if [ ! -f $BASE_IMAGE ]; then
-	if [[ "$CONFIG_GUESTFS_HAS_CUSTOM_RAW_IMAGE" == "y" ]]; then
+	if [[ "${CONFIG_GUESTFS_HAS_CUSTOM_RAW_IMAGE+x}" && "$CONFIG_GUESTFS_HAS_CUSTOM_RAW_IMAGE" == "y" ]]; then
 		build_custom_image
 	fi
 
@@ -305,7 +305,7 @@ if [ ! -f $BASE_IMAGE ]; then
 		copy_yum_repo
 	fi
 
-	if [[ "$CONFIG_GUESTFS_COPY_SOURCES_FROM_HOST_TO_GUEST" == "y" ]]; then
+	if [[ "${CONFIG_GUESTFS_COPY_SOURCES_FROM_HOST_TO_GUEST+x}" && "$CONFIG_GUESTFS_COPY_SOURCES_FROM_HOST_TO_GUEST" == "y" ]]; then
 		copy_host_sources
 	fi
 
@@ -360,7 +360,7 @@ do
 	TZ="$(timedatectl show -p Timezone --value)"
 	$USE_SUDO virt-sysprep -a $ROOTIMG --hostname $name --ssh-inject "kdevops:file:$SSH_KEY.pub" --timezone $TZ
 
-	if [[ "$CONFIG_LIBVIRT_ENABLE_LARGEIO" == "y" ]]; then
+	if [[ "${CONFIG_LIBVIRT_ENABLE_LARGEIO+x}" && "$CONFIG_LIBVIRT_ENABLE_LARGEIO" == "y" ]]; then
 		lbs_idx=0
 		for i in $(seq 1 $(($CONFIG_QEMU_LARGEIO_MAX_POW_LIMIT+1))); do
 			for x in $(seq 0 $CONFIG_QEMU_EXTRA_DRIVE_LARGEIO_NUM_DRIVES_PER_SPACE); do

-- 
2.39.2


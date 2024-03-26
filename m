From: Taylor Jackson <tjackson9431@gmail.com>
Subject: [PATCH 0/2] Patches to update xfs test "generic/645" for
 mount_setattr
Date: Tue, 26 Mar 2024 20:33:50 +0000
Message-Id: <20240326-mount-setattr-test-v1-0-c061b040d0f7@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAC4xA2YC/x3MQQqDQAxA0atI1gZiHKr2KuJisGmbhWOZxCKId
 3dw+Rb/H2CSVQye1QFZ/mq6poKmrmD+xvQR1FcxMHGglh+4rFtyNPHontHFHAcaAoeO5p4JSvj
 L8tb9no7TeV4bHpMcZAAAAA==
To: fstests@vger.kernel.org
Cc: Christian Brauner <brauner@kernel.org>, 
 Seth Forshee <sforshee@kernel.org>, Taylor Jackson <tjackson9431@gmail.com>, 
 kernel test robot <oliver.sang@intel.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711485236; l=835;
 i=tjackson9431@gmail.com; s=20240206; h=from:subject:message-id;
 bh=PMxWRHdvu3D8YQkMSw7UxQB8NcT07jaMLKw5AW6qsVA=;
 b=SPKYaSZcsgzRgXMpio/t7r2Pt5e/Q9GmtvFAxgnKm1oF0dbjXgDG2E7hxm5y8p9FM4ljF0IM7
 mSdgNikKDEVDmJw9z5jjM/FmgPFtCj+B3aQ0l+kjXSEekAdp2gSH2Ce
X-Developer-Key: i=tjackson9431@gmail.com; a=ed25519;
 pk=NO7ntQpjIG1IGTO7F8OnLJDKSHUakhrhAli+PL72OLA=
X-Endpoint-Received: by B4 Relay for tjackson9431@gmail.com/20240206 with auth_id=145
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The following patches fix the "generic/645" xfs test which was 
affected by the mount_setattr change in kernel commit dacfd001eaf2 
(“fs/mnt_idmapping.c: Return -EINVAL when no map is written”). 

Reported-by: kernel test robot <oliver.sang@intel.com>
Closes: https://lore.kernel.org/oe-lkp/202402191416.17ec9160-oliver.sang@intel.com
Signed-off-by: Taylor Jackson <tjackson9431@gmail.com>
---
Taylor Jackson (2):
      vfs/idmapped_mounts.c: Incorrect array index for nested user ns
      vfs/idmapped_mounts.c: Change mount_setattr expected output

 src/vfs/idmapped-mounts.c | 9 ++-------
 1 file changed, 2 insertions(+), 7 deletions(-)
---
base-commit: 9b6df9a01ac8ee3f28a2a24d71e45792e21b6d48
change-id: 20240326-mount-setattr-test-90942470c820

Best regards,
-- 
Taylor Jackson <tjackson9431@gmail.com>


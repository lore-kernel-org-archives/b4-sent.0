From: Taylor Jackson <tjackson9431@gmail.com>
Date: Tue, 26 Mar 2024 20:33:51 +0000
Subject: [PATCH 1/2] vfs/idmapped_mounts.c: Incorrect array index for
 nested user ns
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240326-mount-setattr-test-v1-1-c061b040d0f7@gmail.com>
References: <20240326-mount-setattr-test-v1-0-c061b040d0f7@gmail.com>
In-Reply-To: <20240326-mount-setattr-test-v1-0-c061b040d0f7@gmail.com>
To: fstests@vger.kernel.org
Cc: Christian Brauner <brauner@kernel.org>, 
 Seth Forshee <sforshee@kernel.org>, Taylor Jackson <tjackson9431@gmail.com>, 
 kernel test robot <oliver.sang@intel.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711485236; l=997;
 i=tjackson9431@gmail.com; s=20240206; h=from:subject:message-id;
 bh=BKnBnlQxMR6w2lLKErcrcTyWMWPn+55we5Ja40IlR0M=;
 b=Tc2NSJaI/jjx2h2N++FNwEVoviaql9msmHiGB/4Cp0TYGrg0TbYUHLw3hVC5kZKu3iF4Egz6Z
 80LD7eHGYvqABQm4fNwPF46Plu+cwyCwsdED+6PoA0o56yVeeeT5fZU
X-Developer-Key: i=tjackson9431@gmail.com; a=ed25519;
 pk=NO7ntQpjIG1IGTO7F8OnLJDKSHUakhrhAli+PL72OLA=
X-Endpoint-Received: by B4 Relay for tjackson9431@gmail.com/20240206 with auth_id=145
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Within the vfs test for idmapped mounts, the function nested_userns()
is using an incorrect array index when attempting to set up the mapping
for the 4th nested user ns within hierarchy[4]. The correct index that
belongs to the 4th nested user ns is actually hierarchy[3].
And hierarchy[4] is reserved for the dummy entry that marks the end
of the array.

Signed-off-by: Taylor Jackson <tjackson9431@gmail.com>
---
 src/vfs/idmapped-mounts.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/src/vfs/idmapped-mounts.c b/src/vfs/idmapped-mounts.c
index 547182fe..34052ca3 100644
--- a/src/vfs/idmapped-mounts.c
+++ b/src/vfs/idmapped-mounts.c
@@ -6556,7 +6556,7 @@ static int nested_userns(const struct vfstest_info *info)
 	}
 
 	/* Don't write a mapping in the 4th userns. */
-	list_empty(&hierarchy[4].id_map);
+	list_empty(&hierarchy[3].id_map);
 
 	/* Create the actual userns hierarchy. */
 	ret = create_userns_hierarchy(hierarchy);

-- 
2.34.1


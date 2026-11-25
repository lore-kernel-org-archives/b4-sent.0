From: Sylvain Chouleur <schouleur@snap.com>
Date: Wed, 25 Nov 2026 17:15:53 +0100
Subject: [PATCH] perf/arm-cmn: Use at least 2 bits per XP coordinate in
 node IDs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-arm-cmn-xyidbits-v1-1-6f7bee891859@snap.com>
X-B4-Tracking: v=1; b=H4sIALgJB2sC/yXMQQqDMBBA0avIrB0wA0bxKqWLmIx1BGPJaLGId
 zety7f4/wDlJKzQFQck/ojKEjNMWYAfXXwxSsgGqsgaQzW6NKOfI+5fCb2sisZWjeUwUOsIcvZ
 OPMj+Xz6et3XrJ/br7wPneQGnp47/dAAAAA==
X-Change-ID: 20261125-arm-cmn-xyidbits-16076edf28a2
To: Robin Murphy <robin.murphy@arm.com>, Will Deacon <will@kernel.org>, 
 Mark Rutland <mark.rutland@arm.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-perf-users@vger.kernel.org, 
 stable@vger.kernel.org, Sylvain Chouleur <schouleur@snap.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795623374; l=2076;
 i=schouleur@snap.com; s=20261125; h=from:subject:message-id;
 bh=sa9PZCg2nW0vzlkWYPAJtFCSQhJMIg5Z6aFqeJbc3f0=;
 b=v8agyqySqDUxULbbTkNaysEzgYXGF2W7BwMxU/Z+NgcPXhzJMgZl8a//oBEcG1GqcKYbqI8kz
 7drwmw6dVbvAOmVnsA5sFaXDQwNFBEmM+zMoEN6tmjRLvhpuZbWVJFD
X-Developer-Key: i=schouleur@snap.com; a=ed25519;
 pk=T9TO/S3sm76Hkq5JdP/4AATQ2J2jGtskIHx0NY9lD4I=
X-Endpoint-Received: by B4 Relay for schouleur@snap.com/20261125 with auth_id=1639
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The X and Y coordinates in a CMN/CI-700 node ID are encoded in 2 bits
each for any mesh up to 4x4 (7-bit node IDs), and in 3 bits each for
larger meshes (9-bit node IDs). The width does not shrink for smaller
meshes: a 2x2 mesh still uses 2 bits per coordinate.

arm_cmn_xyidbits() derives the width from the actual mesh dimensions,
which yields 1 bit for a mesh with both dimensions <= 2. On such a
mesh arm_cmn_node_to_xp() then decodes every device on the X=1 column
into the wrong XP: X=1,Y=0 devices are attributed to XP (0,1), and
X=1,Y=1 devices to an index past the end of the XP array. Their PMU
events end up programmed into another XP's DTM, with the port/device
select of the intended XP, so the counters silently read zero while
the rest of the mesh works.

Observed on a CI-700 r3 with a 2x2 mesh (part 0x43a), where the SBSX
and HN-D nodes on the X=1 column never counted although the XP flit
counters showed the traffic. Forcing a minimum of 2 coordinate bits
matches the documented node ID format and makes all nodes count;
the minimum had been there until the node ID refactor dropped it.

Fixes: e79634b53e39 ("perf/arm-cmn: Refactor node ID handling. Again.")
Cc: stable@vger.kernel.org
Signed-off-by: Sylvain Chouleur <schouleur@snap.com>
---
 drivers/perf/arm-cmn.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/perf/arm-cmn.c b/drivers/perf/arm-cmn.c
index 68a096c1fe6b..5f369c7a7a35 100644
--- a/drivers/perf/arm-cmn.c
+++ b/drivers/perf/arm-cmn.c
@@ -406,7 +406,8 @@ struct arm_cmn_nodeid {
 
 static int arm_cmn_xyidbits(const struct arm_cmn *cmn)
 {
-	return fls((cmn->mesh_x - 1) | (cmn->mesh_y - 1));
+	/* Node IDs never use fewer than 2 bits per XP coordinate */
+	return fls((cmn->mesh_x - 1) | (cmn->mesh_y - 1) | 2);
 }
 
 static struct arm_cmn_nodeid arm_cmn_nid(const struct arm_cmn_node *dn)

---
base-commit: 4dce97c6c265544342e716e62fd24bbb232590c5
change-id: 20261125-arm-cmn-xyidbits-16076edf28a2

Best regards,
--  
Sylvain Chouleur <schouleur@snap.com>


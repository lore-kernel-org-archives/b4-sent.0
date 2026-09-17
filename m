From: Andy Chung <Andy.Chung@amd.com>
Subject: [PATCH linux dev-6.18 v2 0/4] hwmon: (kb9002) backport Kandou
 KB9002 retimer support
Date: Thu, 17 Sep 2026 17:49:20 +0800
Message-Id: <20260917-kb9002-backport-v2-0-71d46021f051@amd.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKC3q2oC/3WOyw6CMBREf4XctSW95VFx5X8YFoVepCKUtNBgC
 P8u4NrlZHLOzAqenCEPt2gFR8F4Y4c9iEsEdauGJzGj9wyCi5zLhLOuKjgXrFJ1N1o3sYQnBZJ
 CiVrCTo2OGrOcxge8zTAvkabA8hivUP56P1cvqqdDexCt8ZN1n/NCwJP7uxaQcZZik0pBmRCY3
 VWv49r2UG7b9gXdx51gzgAAAA==
X-Change-ID: 20260730-kb9002-backport-30391ea171d7
To: openbmc@lists.ozlabs.org, andrew@codeconstruct.com.au, 
 tan.siewert@9elements.com
Cc: joel@jms.id.au
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789638570; l=1522;
 i=Andy.Chung@amd.com; s=20260327; h=from:subject:message-id;
 bh=WvLlG+9TFFpIHe3V0qHRidaA1MY9dLqUJ8V5UcdplsQ=;
 b=oOwSzvyaOyoXVgrcNYOq8XDEf2Krx+JPiSS/cX4SaZF+1IoT4pmhQb2RSoGl04RmLXrXHLWS3
 1skF9YDu4OFBLKy7U74PPIcNnq9t5zEqMKCy635fI/FxAKISdY/uUwy
X-Developer-Key: i=Andy.Chung@amd.com; a=ed25519;
 pk=X2gaHRnhU2q5hvMjkC6xmIcC03vKNvHY9CQRdsj9ecM=
X-Endpoint-Received: by B4 Relay for Andy.Chung@amd.com/20260327 with auth_id=696
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The upstream series is in mainline as of v7.3-rc1.

Signed-off-by: Andy Chung <Andy.Chung@amd.com>
---
Changes in v2:
- Redo the backport with "git cherry-pick -x -s" so every commit carries the
  upstream cherry-pick reference and a sign-off, as required by
  openbmc/docs kernel-development.md.
- Record in patch 3/4 that guard(hwmon_lock) was converted to the
  hwmon_lock()/hwmon_unlock() pair, which is the only form dev-6.18 has.
  The code itself is unchanged from v1.
- Link to v1: https://patch.msgid.link/20260730-kb9002-backport-v1-0-41f472e52215@amd.com

---
Andy Chung (4):
      dt-bindings: Add vendor prefix for Kandou
      dt-bindings: trivial-devices: Add Kandou KB9002
      hwmon: (kb9002) Add driver for Kandou KB9002 retimer
      hwmon: (kb9002) Add documentation

 .../devicetree/bindings/trivial-devices.yaml       |   2 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 Documentation/hwmon/index.rst                      |   1 +
 Documentation/hwmon/kb9002.rst                     |  64 +++
 MAINTAINERS                                        |   7 +
 drivers/hwmon/Kconfig                              |  11 +
 drivers/hwmon/Makefile                             |   1 +
 drivers/hwmon/kb9002.c                             | 459 +++++++++++++++++++++
 8 files changed, 547 insertions(+)
---
base-commit: c2b9fc3f7091157518a3ac2282a0a8bc797c227a
change-id: 20260730-kb9002-backport-30391ea171d7

Best regards,
--  
Andy Chung <Andy.Chung@amd.com>


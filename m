From: Daniel Gomez <da.gomez@samsung.com>
Subject: [PATCH RESEND 0/2] MAINTAINERS: add support
Date: Wed, 23 Oct 2024 22:10:28 +0200
Message-Id: <20241023-add-maintainers-file-v1-0-beaa0fdb7f8c@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADRYGWcC/22NPw+CMBTEvwp5s8+05b+Tg6wOOhqGWgq8RIrpQ
 6IhfHcb4uhww93lfrcAW0+W4RAt4O1MTKMLRu4iML12nUVqggclVCKFTFE3DQ6a3BRkPWNLD4t
 ZYvQ9i0WqYgVh+vS2pfeGvcGlulbnE9Qh74mn0X+2t1lu7Q+c/QfPEgXmeSnKIklNXqgj64Ffr
 tubcYB6XdcvfzsqV8IAAAA=
To: Luis Chamberlain <mcgrof@kernel.org>
Cc: "Daniel Gomez (Samsung)" <d@kruces.com>, kdevops@lists.linux.dev, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729714235; l=2002;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=p440oELYNQy556JCwJ9MSUxWUFFX5n1KHmUapgMgGb4=;
 b=IdyhJYZlX1SjGksJyfs0zM8wO51+GOLqGddtZaXYoeHfx4S6l/yk1VR/gpmUfHpcPS/h07Zq5
 zfn1kvny297CqglNVqAKh/BXBUTnJsobZgbHoP9ZF+KlDhtWMGIkviG
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

RESEND patch series (first try was using wrong mail list!).

This introduces support for the MAINTAINERS file (with the same Linux
kernel syntax), get_maintainers.pl, and the b4 configuration file.

With these changes, the MAINTAINERS file can now be used to organize and
manage maintainers, reviewers, and other roles more effectively, similar
to the approach used in the Linux kernel. Additionally, it allows for
reuse of the existing tooling for these tasks (b4 + get_maintainers.pl).

b4 example workflow:

  b4 prep --fork-point origin/main --new add-MAINTAINERS-file

  b4 prep --edit-cover

  b4 prep --auto-to-cc
  Will collect To: addresses using get_maintainer.pl
  Will collect Cc: addresses using get_maintainer.pl
  Collecting To/Cc addresses
      + To: Luis Chamberlain <mcgrof@kernel.org>
      + Cc: linux-kdevops@linux.dev
  ---
  You can trim/expand this list with: b4 prep --edit-cover
  Invoking git-filter-repo to update the cover letter.
  New history written in 0.02 seconds...
  Completely finished after 0.06 seconds

  b4 send

More information can be found here:
https://b4.docs.kernel.org/en/latest/contributor/
overview.html#what-s-the-b4-contributor-workflow

Suggestions on how to split the MAINTAINERS file?

And can we get volunteers to expand this?

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
Changes:
- Added Reviewed by tag.
- Updated kdevops mail list.
- Added myself to the kdevops reviewer list.
- Added GITREF module with myself as reviewer.

---
Daniel Gomez (2):
      MAINTAINERS: add support
      .b4-config: add b4 support

 .b4-config                |    3 +
 MAINTAINERS               |   89 ++
 scripts/get_maintainer.pl | 2642 +++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 2734 insertions(+)
---
base-commit: b829d27a249c315f922c2c289d2a5855aaca19dc
change-id: 20241015-add-maintainers-file-64cab6305232

Best regards,
-- 
Daniel Gomez <da.gomez@samsung.com>


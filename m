From: Petr Hodina <petr.hodina@protonmail.com>
Subject: [PATCH 00/14] expo: Add menu section headers, wrap-around and
 colour control
Date: Sat, 17 Oct 2026 11:10:16 +0200
Message-Id: <20261017-b4-expo-colours-v1-0-479ac06e7642@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM2wpAQBCA4VfRXJuyciivIhd7GIxktYOUvLvF5
 Xfx/xcIBSaBJrkg0MHCfolQaQJ21MtAyC4a8iyvVKZqNAXSuXq0fvZ7ECRrtCt7Z5zWEKs1UM/
 nd2y737Kbiez2buC+H3s+rThzAAAA
X-Change-ID: 20261017-b4-expo-colours-ecbad5fdbdaa
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Anatolij Gustschin <ag.dev.uboot@gmail.com>, 
 Alexander Martinz <amartinz@shiftphones.com>, 
 =?utf-8?q?Guido_G=C3=BCnther?= <agx@sigxcpu.org>, 
 Petr Pavlata <petr@acrux.cz>, David Heidelberg <david@ixit.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792228224; l=2171;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=KvnEcU++M0WzotxiHADNi7rccPpE6AA8Gp3jbsNAXL0=;
 b=UhvnoVOeR96qVBGLchiLukAJyYgel1HvFmyClcXQOfjCn18ea3nXacPQAfB2U5kbAfWUpXt4M
 zAgf+L/iWjyDrih0oV0iKPB6J24dTlwoVCkqUTLe5xAFTPj8w6mb++k
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series extends expo with a few things a menu-driven UI needs:
- section headers in menus
- optional wrap-around when moving past the first or last item
- control over colours

Colours can be set for the background, the highlight, boxes and text objects
including RGB values via a new video_rgb_to_colour() helper.

Each change is opt-in and leaves existing behaviour unchanged and each
comes with a unit test in test/boot/expo.c.

These are prerequisites for the phone boot menu which I sent earlier and 
currently refactoring using the expo. So it's split out here to ease review:

https://lore.kernel.org/all/NlOWu7YfEood1y_dXWzpWRLsMbAPbeVaGxRJ2tfzoYVnA_cNMxZgfBlUX3nZMgiuOPjZanYAWFkYQjn14S487oMfoRpmTcAaiNKg7jcWf08=@protonmail.com/

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Petr Hodina (14):
      expo: Add section headers to menus
      test: expo: Add a test for menu section headers
      expo: Allow a text object to have its own colour
      expo: Allow menus to wrap around
      test: expo: Test menu wrap-around
      video: Add video_rgb_to_colour()
      expo: Allow the background colour to be set
      test: expo: Test setting the background colour
      expo: Allow a box to have its own colour
      test: expo: Test a box with its own colour
      expo: Allow the highlight colours to be set
      test: expo: Test setting the highlight colours
      expo: Allow a text object to have an RGB colour
      test: expo: Test a text object with an RGB colour

 boot/expo.c                  |  49 +++++++--
 boot/scene.c                 |  73 ++++++++++++-
 boot/scene_menu.c            |  56 ++++++++--
 doc/develop/expo.rst         |   7 ++
 drivers/video/video-uclass.c |  27 +++--
 include/expo.h               | 102 ++++++++++++++++++
 include/video.h              |  13 +++
 test/boot/expo.c             | 241 +++++++++++++++++++++++++++++++++++++++++++
 8 files changed, 534 insertions(+), 34 deletions(-)
---
base-commit: 8d534cec0cc0109a37c0ded8854da03f1526dc0e
change-id: 20261017-b4-expo-colours-ecbad5fdbdaa

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>


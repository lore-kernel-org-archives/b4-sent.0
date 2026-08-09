From: Fan Ye <fy15309206903@gmail.com>
Subject: [PATCH net 0/2] net: thunderbolt: two fixes for the failed
 bring-up path
Date: Sun, 09 Aug 2026 02:27:59 +0000
Message-Id: <20260809-b4-tbnet-hopid-v1-0-9a8c7f5f0ba9@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAK/ld2oC/yWMQQ6CMBREr0Jm7U9qA4hexbigZZDPopC2GBPC3
 a26fJN5b0diVCbcqh2RL026hALnUwU/9eFJ0aEwrLGt6cxVXC3ZBWaZllUHaelHNvXF9q5Bkdb
 IUd+/4B3lhsd/TJub6fM3heP4ABLsPe93AAAA
X-Change-ID: 20260809-b4-tbnet-hopid-6ecfe5472ab5
To: Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Fan Ye <fy15309206903@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786242479; l=2114;
 i=fy15309206903@gmail.com; s=tbnet3; h=from:subject:message-id;
 bh=Tjoe12JYyR9weGjE+jcjd8mUOkAu8zSPNPPrgfOdPWU=;
 b=QJ1OZDJKIK2M1C+Z2MuggxBYmu5KRbY1M0f/6gx51Mpwf/FT3KQTnOIe41TTY56kBxonkGAM8
 jZF5PDHbN87BdmhiqSsXp2EyFRVF6qsWgh50KptbU0iesymJ1VvVoCN
X-Developer-Key: i=fy15309206903@gmail.com; a=ed25519;
 pk=6QsQIrI/kruYWIJyCH9ntPMXsHCqF5JtK/DCMtOCzdc=
X-Endpoint-Received: by B4 Relay for fy15309206903@gmail.com/tbnet3 with auth_id=929
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Both of these are reached through the same branch in
tbnet_connected_work(), on an ASMedia ASM4242 host-to-host link, when
the peer drops out while a connection is being brought up. Cycling the
interface down and up 200 times over 80 minutes hits that branch 23
times across the two hosts, with no fault injection.

They fix two separate defects and neither depends on the other for
correctness - each leaves the other's defect in place. Patch 2 does edit
the lines patch 1 adds, so it will not apply on its own and has to come
second.

  1 releases the HopID the allocator actually handed out when it is not
    the one that was asked for. Today that id is simply left allocated
    for the rest of the XDomain connection.

  2 marks the connection as no longer established on the failure paths,
    so the next tbnet_tear_down() does not run a second teardown over
    work that was already undone. That second teardown stops rings that
    were never started, which is a WARNING splat and is fatal under
    panic_on_warn, and it hands back a HopID this connection never owned.

Measured on two ASM4242 hosts from a cold boot, no module reloads, only
the thunderbolt-net module differing between the runs:

                                        without      with
    failed to allocate Rx HopID          11 / 12     9 / 13
    ring already stopped + WARNING       22 / 24     0 / 0
                                     (host A / host B)

Two further patches from the same investigation touch
drivers/thunderbolt/ and go to the thunderbolt tree separately.

Per-patch notes, including what I am not claiming, are below the cut in
each patch.

---
Fan Ye (2):
      net: thunderbolt: Release the Rx HopID that was handed out on mismatch
      net: thunderbolt: Mark the connection down when bringing it up fails

 drivers/net/thunderbolt/main.c | 18 ++++++++++++++++++
 1 file changed, 18 insertions(+)
---
base-commit: 06cf61899d6498b33e4b7c87d99d5bd471ccc375
change-id: 20260809-b4-tbnet-hopid-6ecfe5472ab5

Best regards,
--  
Fan Ye <fy15309206903@gmail.com>


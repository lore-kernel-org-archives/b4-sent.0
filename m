From: Emil Velikov <emil.l.velikov@gmail.com>
Subject: [PATCH BlueZ 00/20] Constify all the things
Date: Tue, 16 Jan 2024 14:00:25 +0000
Message-Id: <20240116-const-v1-0-17c87978f40b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPmLpmUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDQ0Mz3eT8vOIS3aRkS8OUNFNLw1RLYyWg2oKi1LTMCrA50bG1tQClxl0
 wVwAAAA==
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413636; l=4292;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=kh1sBC15ggrzL6V70nVyIyM9BK7L/wflKntRRL2THNU=;
 b=MJhi6vOwX9bJyjH8ZmF0hzGRfofaGOHw4hdM8Zf/bMbdVfpztu8Mq5yI3Utws/NP5J4c7IHQ4
 uzzI+xIUTOZDItTxn0TpxA4cKx2b/epuNC0BuXGPbtgBt2zwOGwCwKT
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello list,

Here is series#2 of the paper cut fixes. Here we annotate a handful of
the data as constant alongside updating all the respective APIs.

There's nothing particularly existing or controversial here, despite the
size of the series. That said, I'm not 100% sure that all code-paths
have been (runtime) tested.

As always - any input will be appreciated.

Thanks
Emil

---
Emil Velikov (20):
      src: const annotate the bluetooth plugin API
      monitor: const annotate util_ltv_debugger instances and API
      monitor: const annotate cmd/handler tables
      monitor: const annotate misc arrays
      monitor: const annotate intel_version_tlv_desc::type_str and API
      monitor: const annotate type_table and related API
      profiles: annotate immutable data as const
      attrib: annotate immutable data as const
      client: annotate struct option instances as const
      emulator: const annotate rfcomm_crc_table[]
      gobex: const annotate RO arrays, use G_N_ELEMENTS
      lib: const annotate hci_map instances and related API
      lib: const annotate tupla instances and API
      mesh: const annotate misc data
      obexd: remove obex_mime_type_driver::set_io_watch
      obexd: const obex_mime_type_driver instances and API
      obexd: const obex_service_driver instances and API
      obexd: const obex_transport_driver instances and API
      obexd: const annotate misc immutable data
      obexd: const annotate obex_plugin_desc entrypoint

 attrib/gatttool.c               |  8 +++---
 attrib/interactive.c            |  2 +-
 client/mgmt.c                   | 42 ++++++++++++++++----------------
 emulator/bthost.c               |  2 +-
 gobex/gobex.c                   |  8 +++---
 lib/hci.c                       | 42 ++++++++++++++++----------------
 lib/hci_lib.h                   |  4 +--
 lib/sdp.c                       | 20 +++++++--------
 mesh/agent.c                    |  4 +--
 monitor/att.c                   | 54 ++++++++++++++++++++---------------------
 monitor/avctp.c                 |  2 +-
 monitor/intel.c                 | 28 ++++++++++-----------
 monitor/l2cap.c                 |  2 +-
 monitor/rfcomm.c                |  2 +-
 monitor/sdp.c                   | 10 ++++----
 obexd/client/manager.c          |  6 ++---
 obexd/client/map.c              |  4 +--
 obexd/client/mns.c              |  8 +++---
 obexd/plugins/bluetooth.c       |  6 ++---
 obexd/plugins/filesystem.c      |  8 +++---
 obexd/plugins/ftp.c             |  2 +-
 obexd/plugins/irmc.c            |  4 +--
 obexd/plugins/mas.c             | 18 +++++++-------
 obexd/plugins/opp.c             |  2 +-
 obexd/plugins/pbap.c            |  8 +++---
 obexd/plugins/pcsuite.c         |  4 +--
 obexd/plugins/phonebook-ebook.c |  2 +-
 obexd/plugins/syncevolution.c   |  4 +--
 obexd/src/genbuiltin            |  4 +--
 obexd/src/main.c                |  2 +-
 obexd/src/mimetype.c            | 26 +++++++-------------
 obexd/src/mimetype.h            | 12 +++++----
 obexd/src/obex-priv.h           |  4 +--
 obexd/src/obex.c                | 18 +++++++-------
 obexd/src/plugin.c              |  8 +++---
 obexd/src/plugin.h              |  4 +--
 obexd/src/server.c              | 10 ++++----
 obexd/src/server.h              |  2 +-
 obexd/src/service.c             | 20 +++++++--------
 obexd/src/service.h             |  6 ++---
 obexd/src/transport.c           | 14 +++++------
 obexd/src/transport.h           |  6 ++---
 profiles/audio/avctp.c          |  2 +-
 profiles/audio/avrcp.c          |  8 +++---
 profiles/audio/media.c          |  6 ++---
 profiles/audio/sink.c           |  2 +-
 profiles/audio/source.c         |  2 +-
 profiles/audio/transport.c      | 12 ++++-----
 profiles/health/hdp_util.c      | 15 ++++++------
 profiles/iap/main.c             |  2 +-
 src/genbuiltin                  |  4 +--
 src/log.c                       |  2 +-
 src/plugin.c                    |  6 ++---
 src/plugin.h                    |  6 ++---
 54 files changed, 251 insertions(+), 258 deletions(-)
---
base-commit: 770ad5614e7e8074133e6f563495ce4822f63fe4
change-id: 20240116-const-bc91df591e93

Best regards,
-- 
Emil Velikov <emil.l.velikov@gmail.com>


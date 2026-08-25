From: Antonin Malzieu Ridolfi <dev@nanonej.com>
Subject: [PATCH 0/4] gpu: nova-core: Extract falcon registers
Date: Wed, 26 Aug 2026 01:44:17 +0200
Message-Id: <20260826-b4-extract-pfsp-registers-to-falcon-mod-v1-0-38351df09084@nanonej.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXNQQrCMBBA0auUWTsQ0yDqVcRFkk7qiCZhJkqh9
 O5GXb7N/ysoCZPCeVhB6M3KJXfsdwPEm88zIU/dYI09mKN1GBzS0sTHhjVpRaGZtZEotoLJP2L
 J+CwTnijYcYyOgiHotSqUePmdLte/9RXuFNs3D9v2AQPfdjqLAAAA
X-Change-ID: 20260824-b4-extract-pfsp-registers-to-falcon-mod-9eb233c4eb0e
To: Danilo Krummrich <dakr@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Alexandre Courbot <acourbot@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>
Cc: linux-kernel@vger.kernel.org, nova-gpu@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, Antonin Malzieu Ridolfi <dev@nanonej.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1951; i=dev@nanonej.com;
 h=from:subject:message-id; bh=yahlqdnVKdlnxPv7kgdCgJdOJCjTzFaRNEl+vby53Eo=;
 b=owEBbQKS/ZANAwAKAWaH8SMKFRX9AcsmYgBqjijxzESK/eGaMHr+EPAPyhvYawjQyQmfITTVS
 zajJ4lOX7OJAjMEAAEKAB0WIQSDtk+wfJEhL1KFIn1mh/EjChUV/QUCao4o8QAKCRBmh/EjChUV
 /UuXEACoo67K7QxxNIrys3YxVZ8cj7nYt/S+aPbV+AWLvJ/7LFEckl98v6FIOVMwGVnwOT+or7R
 T3K8W9K+QFQr5a7FkWu5aorbO33T3UEO1wUaigdm4s2MZnIq/SWMb9N8rAzGaBNUGeDIZ1VGCM0
 SWTqZDMVKNunkErE1EHezeIIqZuxzJU7sLS7LBNYwQ4xWGZ29ibl32HAfO46JFZth5eHUdVpnma
 7/DVYcIBfg7fncPUBWZ+SlZFZoc3B/ITjY8fhKLq3d+W9QyzaxVisxdry1NNNc9eKrR1aeIcy8r
 Vog5YMLI3kHWBX7ZPEqPPm8pzBHFUIr959bW5nzNeVvfA+gQvAOT5+M1uLzneJRrQNJAC9u3FRI
 T++Idtv9CnjDenDGKTJ8tT/laBvTgV8yi1CC+09drc/tNtlsBqrprHaAuNrnw1ErgLIqJqyQ/Gq
 CYYk3HLKKhnW+03VSMfiprvAl8+RSJ+ow//FcrMv42ZLaWpWnvaXQaW6xQjF38FaEGZqaXkmohM
 AAVahj9Fde3NngKLoUxVHVDV6gwLLcByc3PsgLTXagAXrLAqwcrYWP57DY5S2EAckUsINztOzR+
 iHq+ELKfeS0yEMSpiccrtGq+maxo4X8nY0W3awc4C5dox9GhbpJvw7zc2k7RfkPsBfXz7b9G5JD
 n0Ftg577Mw28Jww==
X-Developer-Key: i=dev@nanonej.com; a=openpgp;
 fpr=83B64FB07C91212F5285227D6687F1230A1515FD
X-Endpoint-Received: by B4 Relay for dev@nanonej.com/default with auth_id=825
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move PFSP, PRISCV, PFALCON2, PFALCON registers definitions from the
root regs.rs file into the falcon module.

I tried a different solution than rescoping all  registers with
`crate::super::...` by re-exporting them, hence the comment, but I'm
not sure it's the best solution. I was hoping they would all disapear
by the end of my patch series but as we discussed FUSE register
definitions better stay in the root regs for now.

Also the extract of `set_fbif_transcfg_regs_at()` change some
other functions signature, I think I have covered all but tell me in
case.
And I wasn't sure btw if `.try_at()` required `#[inline()]` there.

Finaly, If I'm correct, this series should conclude the refacto as the
remaining registers seems to be better left in the root regs.rs.

Signed-off-by: Antonin Malzieu Ridolfi <dev@nanonej.com>
---
Antonin Malzieu Ridolfi (4):
      gpu: nova-core: Extract PFSP register definitions
      gpu: nova-core: falcon: Extract PRISCV register
      gpu: nova-core: falcon: Extract PFALCON2 register
      gpu: nova-core: Extract PFALCON register

 drivers/gpu/nova-core/falcon.rs                    |  38 ++-
 drivers/gpu/nova-core/falcon/fsp.rs                |   6 +-
 drivers/gpu/nova-core/falcon/gsp.rs                |  16 +-
 drivers/gpu/nova-core/falcon/hal/ga102.rs          |   4 +-
 drivers/gpu/nova-core/falcon/hal/tu102.rs          |  12 +-
 drivers/gpu/nova-core/falcon/regs.rs               | 304 +++++++++++++++++++++
 drivers/gpu/nova-core/firmware/fwsec/bootloader.rs |  22 +-
 drivers/gpu/nova-core/gsp/hal/tu102.rs             |   7 +-
 drivers/gpu/nova-core/regs.rs                      | 295 +-------------------
 9 files changed, 352 insertions(+), 352 deletions(-)
---
base-commit: d53bc149eea6213e9c4a4604df5521db7b7296ca
change-id: 20260824-b4-extract-pfsp-registers-to-falcon-mod-9eb233c4eb0e

Best regards,
--  
Antonin Malzieu Ridolfi <dev@nanonej.com>


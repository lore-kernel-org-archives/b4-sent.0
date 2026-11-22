From: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
Date: Sun, 22 Nov 2026 11:24:06 -0300
Subject: [PATCH] docs/translations/pt_BR: process: add
 stable-kernel-rules.rst
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261122-stable-kernel-rules-pt-br-v1-1-fc81f73e960e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCMBBG4auUWTtggkr1KuIiqX90NMQykxah9
 O5GXX6L9xYyqMDo1C2kmMXkVRrcpqPhHsoNLNdm8lt/cM57thpiBj+hBZl1yjAeK0dl7F1IMfX
 9zh+p9aMiyfv3Pl/+tik+MNTvkNb1A8eXEgB9AAAA
X-Change-ID: 20261122-stable-kernel-rules-pt-br-e51afbf88429
To: linux-doc@vger.kernel.org
Cc: corbet@lwn.net, rdunlap@infradead.org, danielmaraboo@gmail.com, 
 skhan@linuxfoundation.org, Eduardo Pereira Cruz <dreduardocruz@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795357445; l=12354;
 i=dreduardocruz@gmail.com; s=20261119; h=from:subject:message-id;
 bh=lZeStLtr7kJpAC5eWLji8kOvAThM8balnJfW3WheF64=;
 b=TxjzvgNqF9RBwiZfx/S9BefqMevyE39/9hx0QspC2ilA8ctWZ53iWHLJ0gtmidid3/F1joWEv
 gNjLQ4jp2elAV53RZ1PMmRrapdNd5ullQA5qc85nQUZof5lXLNEm4tG
X-Developer-Key: i=dreduardocruz@gmail.com; a=ed25519;
 pk=2dtL+BL/x70sROmAvlskv9dbjj274zlPkLBVu4gJJiA=
X-Endpoint-Received: by B4 Relay for dreduardocruz@gmail.com/20261119 with auth_id=1571
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Brazilian Portuguese translation of
Documentation/process/stable-kernel-rules.rst, which documents the rules
for patches accepted into the -stable trees and the three ways to submit
a change to them.

The translation follows the English original as last changed by commit
fdd100ee60a0 ("docs: process: use gender-neutral pronouns") and keeps
the cross-reference labels (option_1, option_2, option_3), the literal
blocks with the Cc: tag examples and the note and warning directives.

Signed-off-by: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
---
 Documentation/translations/pt_BR/process/index.rst |   1 +
 .../pt_BR/process/stable-kernel-rules.rst          | 245 +++++++++++++++++++++
 2 files changed, 246 insertions(+)

diff --git a/Documentation/translations/pt_BR/process/index.rst b/Documentation/translations/pt_BR/process/index.rst
index d072f7e46767..34700d52e7ff 100644
--- a/Documentation/translations/pt_BR/process/index.rst
+++ b/Documentation/translations/pt_BR/process/index.rst
@@ -46,6 +46,7 @@ devem estar familiarizados.
    Adicionando uma nova chamada de Sistema <adding-syscalls>
    Por que a classe de tipo "volatile" não deve ser usada <volatile-considered-harmful>
    Como não Deixar as ioctls malfeitas <botching-up-ioctls>
+   Regras para kernels estáveis <stable-kernel-rules>
 
 Guias de políticas e declarações de desenvolvedores
 ---------------------------------------------------
diff --git a/Documentation/translations/pt_BR/process/stable-kernel-rules.rst b/Documentation/translations/pt_BR/process/stable-kernel-rules.rst
new file mode 100644
index 000000000000..3951ae936079
--- /dev/null
+++ b/Documentation/translations/pt_BR/process/stable-kernel-rules.rst
@@ -0,0 +1,245 @@
+.. SPDX-License-Identifier: GPL-2.0
+
+.. _stable_kernel_rules:
+
+Tudo o que você sempre quis saber sobre versões -stable do Linux
+================================================================
+
+Regras sobre que tipo de patch é aceito, e qual não é, na árvore
+"-stable":
+
+- Ele, ou uma correção equivalente, já deve existir no mainline do Linux
+  (upstream).
+- Deve ser obviamente correto e testado.
+- Não pode ser maior que 100 linhas, com contexto.
+- Deve seguir as regras de
+  :ref:`Documentation/process/submitting-patches.rst <submittingpatches>`.
+- Deve corrigir um bug real que incomoda as pessoas ou apenas adicionar um ID
+  de dispositivo. Detalhando o primeiro caso:
+
+  - Corrige um problema como um oops, um travamento, corrupção de dados, um
+    problema real de segurança, uma peculiaridade de hardware, um erro de
+    compilação (mas não para coisas marcadas como CONFIG_BROKEN) ou algum
+    problema do tipo "ah, isso não é bom".
+  - Problemas graves relatados por um usuário de kernel de distribuição também
+    podem ser considerados, se corrigirem um problema notável de desempenho
+    ou de interatividade. Como essas correções não são tão óbvias e têm maior
+    risco de regressão sutil, devem ser enviadas apenas por um mantenedor de
+    kernel de distribuição e incluir um adendo com link para uma entrada no
+    bugzilla, se existir, e informações adicionais sobre o impacto visível ao
+    usuário.
+  - Nada do tipo "isto poderia ser um problema...", como uma "condição de
+    corrida teórica", a menos que também seja fornecida uma explicação de
+    como o bug pode ser explorado.
+  - Nada de correções "triviais" sem benefício para os usuários (mudanças de
+    ortografia, limpeza de espaços em branco etc.).
+
+
+Procedimento para enviar patches para a árvore -stable
+------------------------------------------------------
+
+.. note::
+
+   Patches de segurança não devem ser tratados (somente) pelo processo de
+   revisão do -stable, mas devem seguir os procedimentos em
+   :ref:`Documentation/process/security-bugs.rst <securitybugs>`.
+
+Há três opções para enviar uma mudança para as árvores -stable:
+
+1. Adicione uma 'tag stable' à descrição de um patch que você envia para
+   inclusão no mainline.
+2. Peça à equipe stable para pegar um patch que já está no mainline.
+3. Envie à equipe stable um patch equivalente a uma mudança que já está no
+   mainline.
+
+As seções abaixo descrevem cada opção em mais detalhes.
+
+:ref:`option_1` é **fortemente** preferida: é a mais fácil e a mais comum.
+:ref:`option_2` destina-se principalmente a mudanças em que o backport não foi
+considerado no momento do envio. :ref:`option_3` é uma alternativa às duas
+opções anteriores para casos em que um patch já no mainline precisa de ajustes
+para ser aplicado em séries mais antigas (por exemplo, devido a mudanças de API).
+
+Ao usar a opção 2 ou 3, você pode pedir que a sua mudança seja incluída em
+séries stable específicas. Ao fazer isso, garanta que a correção, ou algo
+equivalente, seja aplicável, esteja enviada ou já esteja presente em todas as
+árvores stable mais novas ainda suportadas. Isso serve para evitar regressões
+que os usuários possam encontrar mais tarde ao atualizar, caso, por exemplo,
+uma correção mesclada para 5.19-rc1 seja levada por backport para 5.10.y, mas
+não para 5.15.y.
+
+.. _option_1:
+
+Opção 1
+*******
+
+Para que um patch enviado para inclusão no mainline seja mais tarde pego
+automaticamente para as árvores stable, adicione esta tag na área de
+trailers de assinatura::
+
+  Cc: stable@vger.kernel.org
+
+Use ``Cc: stable@kernel.org`` em vez disso ao corrigir vulnerabilidades não
+publicadas: isso reduz a chance de expor acidentalmente a correção ao
+público por meio de 'git send-email', já que mensagens enviadas para esse
+endereço não são entregues a ninguém.
+
+Depois que o patch estiver no mainline, ele será aplicado à árvore stable sem
+que nada mais precise ser feito pelo autor ou pelo mantenedor do subsistema.
+
+Para enviar instruções adicionais à equipe stable, use um comentário em linha
+no estilo shell para passar notas arbitrárias ou predefinidas:
+
+* Especifique pré-requisitos adicionais de patch para o cherry picking::
+
+    Cc: <stable@vger.kernel.org> # 3.3.x: a1f84a3: sched: Check for idle
+    Cc: <stable@vger.kernel.org> # 3.3.x: 1b9508f: sched: Rate-limit newidle
+    Cc: <stable@vger.kernel.org> # 3.3.x: fd21073: sched: Fix affinity logic
+    Cc: <stable@vger.kernel.org> # 3.3.x
+    Signed-off-by: Ingo Molnar <mingo@elte.hu>
+
+  A sequência de tags tem o significado de::
+
+    git cherry-pick a1f84a3
+    git cherry-pick 1b9508f
+    git cherry-pick fd21073
+    git cherry-pick <this commit>
+
+  Note que, para uma série de patches, você não precisa listar como
+  pré-requisitos os patches presentes na própria série. Por exemplo, se você
+  tem a seguinte série de patches::
+
+    patch1
+    patch2
+
+  em que patch2 depende de patch1, você não precisa listar patch1 como
+  pré-requisito de patch2 se já marcou patch1 para inclusão no stable.
+
+* Aponte pré-requisitos de versão do kernel::
+
+    Cc: <stable@vger.kernel.org> # 3.3.x
+
+  A tag tem o significado de::
+
+    git cherry-pick <this commit>
+
+  Para cada árvore "-stable" começando na versão especificada.
+
+  Note que essa marcação é desnecessária se a equipe stable conseguir derivar
+  as versões apropriadas a partir de tags Fixes:.
+
+* Atrase a coleta de patches::
+
+    Cc: <stable@vger.kernel.org> # after -rc3
+
+* Aponte problemas conhecidos::
+
+    Cc: <stable@vger.kernel.org> # see patch description, needs adjustments for <= 6.3
+
+Há ainda uma variante da tag stable que você pode usar para fazer as
+ferramentas de backport da equipe stable (por exemplo, AUTOSEL ou scripts que
+procuram commits contendo uma tag 'Fixes:') ignorarem uma mudança::
+
+     Cc: <stable+noautosel@kernel.org> # reason goes here, and must be present
+
+.. _option_2:
+
+Opção 2
+*******
+
+Se o patch já foi mesclado no mainline, envie um e-mail para
+stable@vger.kernel.org contendo o assunto do patch, o ID do commit, por que
+você acha que ele deve ser aplicado e a quais versões do kernel você deseja
+que ele seja aplicado.
+
+.. _option_3:
+
+Opção 3
+*******
+
+Envie o patch, após verificar que ele segue as regras acima, para
+stable@vger.kernel.org e mencione as versões do kernel às quais você deseja
+que ele seja aplicado. Ao fazer isso, você deve anotar o ID do commit
+upstream no changelog do seu envio, em uma linha separada acima do texto do
+commit, assim::
+
+  commit <sha1> upstream.
+
+Ou, alternativamente::
+
+  [ Upstream commit <sha1> ]
+
+Se o patch enviado se desviar do patch upstream original (por exemplo, porque
+teve de ser ajustado para a API mais antiga), isso deve ser documentado e
+justificado com muita clareza na descrição do patch.
+
+
+Após o envio
+------------
+
+O remetente receberá um ACK quando o patch for aceito na fila, ou um NAK se o
+patch for rejeitado. Essa resposta pode levar alguns dias, conforme a agenda
+dos membros da equipe stable.
+
+Se aceito, o patch será adicionado à fila do -stable, para revisão por outros
+desenvolvedores e pelo mantenedor do subsistema correspondente.
+
+
+Ciclo de revisão
+-----------------
+
+- Quando os mantenedores do -stable decidem por um ciclo de revisão, os
+  patches são enviados ao comitê de revisão, ao mantenedor da área afetada
+  pelo patch (a menos que o remetente seja o mantenedor da área) e com CC
+  para a lista de discussão linux-kernel.
+- O comitê de revisão tem 48 horas para dar ACK ou NAK no patch.
+- Se o patch for rejeitado por um membro do comitê, ou se membros da
+  linux-kernel se opuserem ao patch, levantando questões que os mantenedores
+  e os membros não haviam percebido, o patch será retirado da fila.
+- Os patches com ACK serão publicados novamente como parte de um release
+  candidate (-rc) para serem testados por desenvolvedores e testadores.
+- Normalmente apenas um -rc é lançado; porém, se houver questões pendentes,
+  alguns patches podem ser modificados ou descartados, ou patches adicionais
+  podem ser enfileirados. Novos -rc são então lançados e testados até que
+  nenhum problema seja encontrado.
+- Responder aos -rc pode ser feito na lista de discussão enviando um e-mail
+  com "Tested-by:" e qualquer informação de teste desejada. As tags
+  "Tested-by:" serão coletadas e adicionadas ao commit da versão.
+- Ao final do ciclo de revisão, a nova versão -stable será lançada contendo
+  todos os patches enfileirados e testados.
+- Patches de segurança serão aceitos na árvore -stable diretamente da equipe
+  de segurança do kernel, e não passarão pelo ciclo de revisão normal. Entre
+  em contato com a equipe de segurança do kernel para mais detalhes sobre
+  esse procedimento.
+
+
+Árvores
+-------
+
+- As filas de patches, tanto das versões concluídas quanto das versões em
+  andamento, podem ser encontradas em:
+
+    https://git.kernel.org/pub/scm/linux/kernel/git/stable/stable-queue.git
+
+- As versões finalizadas e marcadas com tag de todos os kernels stable podem ser
+  encontradas em ramos separados por versão em:
+
+    https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
+
+- O release candidate de todas as versões de kernel stable pode ser encontrado
+  em:
+
+    https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable-rc.git/
+
+  .. warning::
+     A árvore -stable-rc é um instantâneo da árvore stable-queue e mudará
+     com frequência, portanto será rebaseada com frequência. Ela deve ser
+     usada apenas para fins de teste (por exemplo, para consumo por sistemas
+     de CI).
+
+
+Comitê de revisão
+------------------
+
+- Ele é composto por vários desenvolvedores do kernel que se ofereceram como
+  voluntários para essa tarefa, e alguns que não se ofereceram.

---
base-commit: 4405c18c95d2d0f99f6c581ef0ee8591a1aa6ccd
change-id: 20261122-stable-kernel-rules-pt-br-e51afbf88429

Best regards,
--  
Eduardo Pereira Cruz <dreduardocruz@gmail.com>


import { workflow, node, links } from '@n8n-as-code/transformer';

// <workflow-map>
// Workflow : Jarvis - Ping
// Nodes   : 2  |  Connections: 1
//
// NODE INDEX
// ──────────────────────────────────────────────────────────────────
// Property name                    Node type (short)         Flags
// Demarrer                           manualTrigger
// Resultat                           set
//
// ROUTING MAP
// ──────────────────────────────────────────────────────────────────
// Demarrer
//    → Resultat
// </workflow-map>

// =====================================================================
// METADATA DU WORKFLOW
// =====================================================================

@workflow({
    id: 'pAEGDryTzsOIhc74',
    name: 'Jarvis - Ping',
    active: false,
    isArchived: false,
    settings: { executionOrder: 'v1', callerPolicy: 'workflowsFromSameOwner', availableInMCP: false },
})
export class JarvisPingWorkflow {
    // =====================================================================
    // CONFIGURATION DES NOEUDS
    // =====================================================================

    @node({
        id: '391e35b5-af71-45cf-ac9a-6680f953d44c',
        name: 'Démarrer',
        type: 'n8n-nodes-base.manualTrigger',
        version: 1,
        position: [250, 300],
    })
    Demarrer = {};

    @node({
        id: '3f89db8c-778a-46b6-bbc8-620117b4c517',
        name: 'Résultat',
        type: 'n8n-nodes-base.set',
        version: 3.4,
        position: [520, 300],
    })
    Resultat = {
        mode: 'manual',
        fields: {
            values: [
                {
                    name: 'statut',
                    type: 'stringValue',
                    stringValue: 'connecte',
                },
                {
                    name: 'message',
                    type: 'stringValue',
                    stringValue: 'Jarvis est bien connecte a n8n',
                },
                {
                    name: 'instance',
                    type: 'stringValue',
                    stringValue: 'localhost:5678',
                },
            ],
        },
    };

    // =====================================================================
    // ROUTAGE ET CONNEXIONS
    // =====================================================================

    @links()
    defineRouting() {
        this.Demarrer.out(0).to(this.Resultat.in(0));
    }
}

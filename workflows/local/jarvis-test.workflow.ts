import { workflow, node, links } from '@n8n-as-code/transformer';

// <workflow-map>
// Workflow : Jarvis - Test Connexion
// Nodes   : 2  |  Connections: 1
//
// NODE INDEX
// ──────────────────────────────────────────────────────────────────
// Property name                    Node type (short)         Flags
// Webhook                            webhook
// Repondre                           respondToWebhook
//
// ROUTING MAP
// ──────────────────────────────────────────────────────────────────
// Webhook
//    → Repondre
// </workflow-map>

// =====================================================================
// METADATA DU WORKFLOW
// =====================================================================

@workflow({
    id: 'crHHdbGvdDFKjFfj',
    name: 'Jarvis - Test Connexion',
    active: false,
    isArchived: false,
    settings: { executionOrder: 'v1', callerPolicy: 'workflowsFromSameOwner', availableInMCP: false },
})
export class JarvisTestConnexionWorkflow {
    // =====================================================================
    // CONFIGURATION DES NOEUDS
    // =====================================================================

    @node({
        id: '6085fbef-e320-4e49-972a-d281794bbaf8',
        webhookId: 'd541d964-5d23-4cf3-b77e-7913b60f144e',
        name: 'Webhook',
        type: 'n8n-nodes-base.webhook',
        version: 2.1,
        position: [250, 300],
    })
    Webhook = {
        responseBinaryPropertyName: 'data',
        httpMethod: 'GET',
        path: 'jarvis-test',
        responseMode: 'responseNode',
    };

    @node({
        id: 'a985717d-ae4a-4817-b295-9762de0efcd5',
        name: 'Repondre',
        type: 'n8n-nodes-base.respondToWebhook',
        version: 1.5,
        position: [520, 300],
    })
    Repondre = {
        redirectURL: '',
        inputFieldName: 'data',
        respondWith: 'json',
        responseBody: {
            message: 'Hello from Jarvis !',
            status: 'connecte',
            instance: 'n8n localhost:5678',
        },
    };

    // =====================================================================
    // ROUTAGE ET CONNEXIONS
    // =====================================================================

    @links()
    defineRouting() {
        this.Webhook.out(0).to(this.Repondre.in(0));
    }
}

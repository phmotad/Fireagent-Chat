import { frontendURL } from '../../../helper/URLHelper';
import SettingWrapper from '../settings/SettingsWrapper.vue';

const AgentIndex = () => import('./pages/AgentIndex.vue');
const AgentSettings = () => import('./pages/AgentSettings.vue');
const AgentInboxes = () => import('./pages/AgentInboxes.vue');
const AgentInboxesList = () => import('./pages/AgentInboxesList.vue');
const AgentKnowledge = () => import('./pages/AgentKnowledge.vue');
const AgentKnowledgeList = () => import('./pages/AgentKnowledgeList.vue');
const AgentTools = () => import('./pages/AgentTools.vue');
const AgentToolsList = () => import('./pages/AgentToolsList.vue');

export default {
    routes: [
        {
            path: frontendURL('accounts/:accountId/agents'),
            component: SettingWrapper,
            children: [
                // Configurações (Lista de agentes)
                {
                    path: 'settings',
                    name: 'agent_settings',
                    component: AgentIndex,
                    meta: {
                        permissions: ['administrator'],
                    },
                },
                // Criar novo agente
                {
                    path: 'settings/new',
                    name: 'agent_settings_new',
                    component: AgentSettings,
                    meta: {
                        permissions: ['administrator'],
                    },
                },
                // Editar agente específico
                {
                    path: 'settings/:agentId',
                    name: 'agent_settings_edit',
                    component: AgentSettings,
                    meta: {
                        permissions: ['administrator'],
                    },
                },
                // Conhecimento (Lista de agentes)
                {
                    path: 'knowledge',
                    name: 'agent_knowledge',
                    component: AgentKnowledgeList,
                    meta: {
                        permissions: ['administrator'],
                    },
                },
                // Conhecimento de um agente específico
                {
                    path: 'knowledge/:agentId',
                    name: 'agent_knowledge_edit',
                    component: AgentKnowledge,
                    meta: {
                        permissions: ['administrator'],
                    },
                },
                // Ferramentas (Lista de agentes)
                {
                    path: 'tools',
                    name: 'agent_tools',
                    component: AgentToolsList,
                    meta: {
                        permissions: ['administrator'],
                    },
                },
                // Ferramentas de um agente específico
                {
                    path: 'tools/:agentId',
                    name: 'agent_tools_edit',
                    component: AgentTools,
                    meta: {
                        permissions: ['administrator'],
                    },
                },
                // Caixas de Entrada (Lista de agentes)
                {
                    path: 'inboxes',
                    name: 'agent_inboxes',
                    component: AgentInboxesList,
                    meta: {
                        permissions: ['administrator'],
                    },
                },
                // Caixas de Entrada de um agente específico
                {
                    path: 'inboxes/:agentId',
                    name: 'agent_inboxes_edit',
                    component: AgentInboxes,
                    meta: {
                        permissions: ['administrator'],
                    },
                },
            ],
        },
    ],
};

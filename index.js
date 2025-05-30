import React, { useState, useCallback, useMemo } from 'react';
import {
ReactFlow,
MiniMap,
Controls,
Background,
useNodesState,
useEdgesState,
addEdge,
Panel
} from 'reactflow';
import 'reactflow/dist/style.css';
import {
Play,
Pause,
Settings,
Plus,
Save,
Download,
Upload,
Zap,
Cpu,
Send,
Database,
Globe,
MessageSquare,
Timer,
Camera,
FileText
} from 'lucide-react';

// Node types for different pipeline components
const TriggerNode = ({ data, isConnectable }) => (
<div className="px-4 py-3 shadow-lg rounded-lg bg-blue-500 text-white border-2 border-blue-600 min-w-48">
    <div className="flex items-center gap-2 mb-2">
        <Zap size={16} />
        <span className="font-semibold">Trigger</span>
    </div>
    <div className="text-sm">
        <div className="font-medium">{data.label}</div>
        <div className="text-blue-100 text-xs">{data.type}</div>
    </div>
    <div className="flex justify-end mt-2">
        <div className="w-3 h-3 bg-white rounded-full" />
    </div>
</div>
);

const ProcessorNode = ({ data, isConnectable }) => (
<div className="px-4 py-3 shadow-lg rounded-lg bg-green-500 text-white border-2 border-green-600 min-w-48">
    <div className="flex items-center gap-2 mb-2">
        <Cpu size={16} />
        <span className="font-semibold">Processor</span>
    </div>
    <div className="text-sm">
        <div className="font-medium">{data.label}</div>
        <div className="text-green-100 text-xs">{data.language}</div>
        {data.parallel && <div className="text-green-100 text-xs">⚡ Parallel</div>}
    </div>
    <div className="flex justify-between items-center mt-2">
        <div className="w-3 h-3 bg-white rounded-full" />
        <div className="w-3 h-3 bg-white rounded-full" />
    </div>
</div>
);

const OutputNode = ({ data, isConnectable }) => (
<div className="px-4 py-3 shadow-lg rounded-lg bg-purple-500 text-white border-2 border-purple-600 min-w-48">
    <div className="flex items-center gap-2 mb-2">
        <Send size={16} />
        <span className="font-semibold">Output</span>
    </div>
    <div className="text-sm">
        <div className="font-medium">{data.label}</div>
        <div className="text-purple-100 text-xs">{data.type}</div>
        {data.condition && <div className="text-purple-100 text-xs">📋 Conditional</div>}
    </div>
    <div className="flex justify-start mt-2">
        <div className="w-3 h-3 bg-white rounded-full" />
    </div>
</div>
);

const nodeTypes = {
triggerNode: TriggerNode,
processorNode: ProcessorNode,
outputNode: OutputNode,
};

// Component palette for drag and drop
const ComponentPalette = ({ onAddNode }) => {
const components = [
{
category: 'Triggers',
items: [
{ type: 'http', label: 'HTTP API', icon: Globe },
{ type: 'mqtt', label: 'MQTT', icon: MessageSquare },
{ type: 'timer', label: 'Timer', icon: Timer },
{ type: 'file_watch', label: 'File Watch', icon: FileText },
{ type: 'websocket', label: 'WebSocket', icon: Globe },
]
},
{
category: 'Processors',
items: [
{ type: 'python', label: 'Python Script', icon: FileText },
{ type: 'go', label: 'Go Binary', icon: Cpu },
{ type: 'rust_wasm', label: 'Rust WASM', icon: Zap },
{ type: 'node', label: 'Node.js', icon: FileText },
{ type: 'docker', label: 'Docker', icon: Database },
{ type: 'llm', label: 'LLM', icon: MessageSquare },
]
},
{
category: 'Outputs',
items: [
{ type: 'email', label: 'Email', icon: Send },
{ type: 'database', label: 'Database', icon: Database },
{ type: 'http', label: 'HTTP', icon: Globe },
{ type: 'mqtt', label: 'MQTT', icon: MessageSquare },
{ type: 'file', label: 'File', icon: FileText },
]
}
];

return (
<div className="w-64 bg-gray-50 border-r border-gray-200 p-4 overflow-y-auto">
    <h3 className="font-semibold text-gray-800 mb-4">Components</h3>
    {components.map(category => (
    <div key={category.category} className="mb-6">
        <h4 className="font-medium text-gray-600 mb-2 text-sm uppercase tracking-wide">
            {category.category}
        </h4>
        <div className="space-y-2">
            {category.items.map(item => {
            const Icon = item.icon;
            return (
            <button
                    key={item.type}
                    onClick={() => onAddNode(category.category.toLowerCase().slice(0, -1), item)}
            className="w-full flex items-center gap-2 p-2 bg-white border border-gray-200 rounded-lg hover:bg-gray-50 hover:border-gray-300 transition-colors text-left"
            >
            <Icon size={16} className="text-gray-600" />
            <span className="text-sm text-gray-700">{item.label}</span>
            </button>
            );
            })}
        </div>
    </div>
    ))}
</div>
);
};

// Properties panel for configuring selected nodes
const PropertiesPanel = ({ selectedNode, onUpdateNode }) => {
const [config, setConfig] = useState(selectedNode?.data || {});

const handleConfigChange = (key, value) => {
const newConfig = { ...config, [key]: value };
setConfig(newConfig);
onUpdateNode(selectedNode.id, newConfig);
};

if (!selectedNode) {
return (
<div className="w-80 bg-gray-50 border-l border-gray-200 p-4">
    <div className="text-center text-gray-500 mt-8">
        <Settings size={48} className="mx-auto mb-4 text-gray-300" />
        <p>Select a node to configure its properties</p>
    </div>
</div>
);
}

const renderTriggerConfig = () => (
<div className="space-y-4">
    <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
        <input
                type="text"
                value={config.label || ''}
        onChange={(e) => handleConfigChange('label', e.target.value)}
        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
        />
    </div>

    {config.type === 'http' && (
    <>
    <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Port</label>
        <input
                type="number"
                value={config.port || 8080}
                onChange={(e) => handleConfigChange('port', parseInt(e.target.value))}
        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
        />
    </div>
    <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Path</label>
        <input
                type="text"
                value={config.path || '/'}
        onChange={(e) => handleConfigChange('path', e.target.value)}
        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
        />
    </div>
</>
)}

{config.type === 'mqtt' && (
<>
<div>
    <label className="block text-sm font-medium text-gray-700 mb-1">Broker URL</label>
    <input
            type="text"
            value={config.broker || 'mqtt://localhost:1883'}
    onChange={(e) => handleConfigChange('broker', e.target.value)}
    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
    />
</div>
<div>
    <label className="block text-sm font-medium text-gray-700 mb-1">Topic</label>
    <input
            type="text"
            value={config.topic || 'data/input'}
    onChange={(e) => handleConfigChange('topic', e.target.value)}
    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
    />
</div>
</>
)}

{config.type === 'timer' && (
<div>
    <label className="block text-sm font-medium text-gray-700 mb-1">Interval (ms)</label>
    <input
            type="number"
            value={config.interval || 30000}
            onChange={(e) => handleConfigChange('interval', parseInt(e.target.value))}
    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
    />
</div>
)}
</div>
);

const renderProcessorConfig = () => (
<div className="space-y-4">
    <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
        <input
                type="text"
                value={config.label || ''}
        onChange={(e) => handleConfigChange('label', e.target.value)}
        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-green-500"
        />
    </div>

    {config.language === 'python' && (
    <>
    <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Script Path</label>
        <input
                type="text"
                value={config.script || 'script.py'}
        onChange={(e) => handleConfigChange('script', e.target.value)}
        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-green-500"
        />
    </div>
    <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Virtual Environment</label>
        <input
                type="text"
                value={config.venv || ''}
        onChange={(e) => handleConfigChange('venv', e.target.value)}
        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-green-500"
        placeholder="/opt/ml-env"
        />
    </div>
</>
)}

{config.language === 'go' && (
<>
<div>
    <label className="block text-sm font-medium text-gray-700 mb-1">Binary Path</label>
    <input
            type="text"
            value={config.binary || './processor'}
    onChange={(e) => handleConfigChange('binary', e.target.value)}
    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-green-500"
    />
</div>
<div>
    <label className="block text-sm font-medium text-gray-700 mb-1">Arguments</label>
    <input
            type="text"
            value={config.args?.join(' ') || ''}
    onChange={(e) => handleConfigChange('args', e.target.value.split(' ').filter(Boolean))}
    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-green-500"
    placeholder="--flag=value --other-flag"
    />
</div>
</>
)}

<div>
    <label className="block text-sm font-medium text-gray-700 mb-1">Timeout (ms)</label>
    <input
            type="number"
            value={config.timeout || 5000}
            onChange={(e) => handleConfigChange('timeout', parseInt(e.target.value))}
    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-green-500"
    />
</div>

<div className="flex items-center">
    <input
            type="checkbox"
            id="parallel"
            checked={config.parallel || false}
            onChange={(e) => handleConfigChange('parallel', e.target.checked)}
    className="h-4 w-4 text-green-600 focus:ring-green-500 border-gray-300 rounded"
    />
    <label htmlFor="parallel" className="ml-2 block text-sm text-gray-700">
        Enable parallel processing
    </label>
</div>

<div>
    <label className="block text-sm font-medium text-gray-700 mb-1">Environment Variables</label>
    <textarea
            value={Object.entries(config.environment || {}).map(([k, v]) => `${k}=${v}`).join('\n')}
          onChange={(e) => {
            const env = {};
            e.target.value.split('\n').forEach(line => {
              const [key, ...valueParts] = line.split('=');
              if (key && valueParts.length > 0) {
                env[key.trim()] = valueParts.join('=').trim();
              }
            });
            handleConfigChange('environment', env);
          }}
          placeholder="KEY=value&#10;ANOTHER_KEY=another_value"
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-green-500"
          rows={3}
        />
      </div>
    </div>
  );

  const renderOutputConfig = () => (
    <div className="space-y-4">
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
        <input
          type="text"
          value={config.label || ''}
          onChange={(e) => handleConfigChange('label', e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-purple-500 focus:border-purple-500"
        />
      </div>

      {config.type === 'email' && (
        <>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">SMTP Server</label>
            <input
              type="text"
              value={config.smtp || 'smtp://localhost:587'}
              onChange={(e) => handleConfigChange('smtp', e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-purple-500 focus:border-purple-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Recipients</label>
            <input
              type="text"
              value={config.to?.join(', ') || ''}
              onChange={(e) => handleConfigChange('to', e.target.value.split(',').map(s => s.trim()).filter(Boolean))}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-purple-500 focus:border-purple-500"
              placeholder="user1@example.com, user2@example.com"
            />
          </div>
        </>
      )}

      {config.type === 'http' && (
        <>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">URL</label>
            <input
              type="text"
              value={config.url || 'https://api.example.com/webhook'}
              onChange={(e) => handleConfigChange('url', e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-purple-500 focus:border-purple-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Method</label>
            <select
              value={config.method || 'POST'}
              onChange={(e) => handleConfigChange('method', e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-purple-500 focus:border-purple-500"
            >
              <option value="POST">POST</option>
              <option value="PUT">PUT</option>
              <option value="PATCH">PATCH</option>
            </select>
          </div>
        </>
      )}

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Condition (optional)</label>
        <input
          type="text"
          value={config.condition || ''}
          onChange={(e) => handleConfigChange('condition', e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-purple-500 focus:border-purple-500"
          placeholder="threat_level > 0.8"
        />
      </div>
    </div>
  );

  return (
    <div className="w-80 bg-gray-50 border-l border-gray-200 p-4 overflow-y-auto">
      <div className="flex items-center gap-2 mb-4">
        <Settings size={20} className="text-gray-600" />
        <h3 className="font-semibold text-gray-800">Properties</h3>
      </div>

      <div className="bg-white rounded-lg p-4 border border-gray-200">
        <div className="mb-4">
          <span className="inline-block px-2 py-1 text-xs font-medium bg-gray-100 text-gray-700 rounded">
            {selectedNode.type}
          </span>
        </div>

        {selectedNode.type === 'triggerNode' && renderTriggerConfig()}
        {selectedNode.type === 'processorNode' && renderProcessorConfig()}
        {selectedNode.type === 'outputNode' && renderOutputConfig()}
      </div>
    </div>
  );
};

// Main pipeline editor component
const DialogChainVisualEditor = () => {
  const [nodes, setNodes, onNodesChange] = useNodesState([]);
  const [edges, setEdges, onEdgesChange] = useEdgesState([]);
  const [selectedNode, setSelectedNode] = useState(null);
  const [isRunning, setIsRunning] = useState(false);
  const [pipelineName, setPipelineName] = useState('untitled_pipeline');

  const onConnect = useCallback((params) => setEdges((eds) => addEdge(params, eds)), [setEdges]);

  const onAddNode = useCallback((category, item) => {
    const id = `${category}_${Date.now()}`;
    const position = { x: Math.random() * 400, y: Math.random() * 400 };

    let newNode;
    if (category === 'trigger') {
      newNode = {
        id,
        type: 'triggerNode',
        position,
        data: {
          label: item.label,
          type: item.type,
          ...getDefaultConfig(category, item.type)
        },
      };
    } else if (category === 'processor') {
      newNode = {
        id,
        type: 'processorNode',
        position,
        data: {
          label: item.label,
          language: item.type,
          parallel: item.type !== 'llm',
          ...getDefaultConfig(category, item.type)
        },
      };
    } else if (category === 'output') {
      newNode = {
        id,
        type: 'outputNode',
        position,
        data: {
          label: item.label,
          type: item.type,
          ...getDefaultConfig(category, item.type)
        },
      };
    }

    setNodes((nds) => nds.concat(newNode));
  }, [setNodes]);

  const getDefaultConfig = (category, type) => {
    const defaults = {
      trigger: {
        http: { port: 8080, path: '/webhook' },
        mqtt: { broker: 'mqtt://localhost:1883', topic: 'data/input' },
        timer: { interval: 30000 },
        file_watch: { path: '/watch', pattern: '*' },
        websocket: { port: 8080, endpoint: '/ws' }
      },
      processor: {
        python: { script: 'processor.py', timeout: 5000, retry: 2 },
        go: { binary: './processor', timeout: 3000, retry: 1 },
        rust_wasm: { wasm: 'processor.wasm', timeout: 1000, retry: 0 },
        node: { script: 'processor.js', timeout: 3000, retry: 2 },
        docker: { image: 'processor:latest', timeout: 10000, retry: 1 },
        llm: { model: 'gpt-4', timeout: 15000, retry: 1 }
      },
      output: {
        email: { smtp: 'smtp://localhost:587', to: [] },
        database: { connection: 'postgresql://localhost/db', table: 'events' },
        http: { url: 'https://api.example.com/webhook', method: 'POST' },
        mqtt: { broker: 'mqtt://localhost:1883', topic: 'data/output' },
        file: { path: '/output', format: 'json' }
      }
    };

    return defaults[category]?.[type] || {};
  };

  const onNodeClick = useCallback((event, node) => {
    setSelectedNode(node);
  }, []);

  const onUpdateNode = useCallback((nodeId, newData) => {
    setNodes((nds) =>
      nds.map((node) =>
        node.id === nodeId ? { ...node, data: { ...node.data, ...newData } } : node
      )
    );
  }, [setNodes]);

  const onRunPipeline = () => {
    setIsRunning(!isRunning);
    // Here you would integrate with the actual DialogChain engine
    console.log('Pipeline execution toggled:', { isRunning: !isRunning, nodes, edges });
  };

  const onSavePipeline = () => {
    const config = generateYAMLConfig(nodes, edges, pipelineName);
    const blob = new Blob([config], { type: 'text/yaml' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${pipelineName}.yaml`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const generateYAMLConfig = (nodes, edges, name) => {
    const triggers = nodes.filter(n => n.type === 'triggerNode').map(n => ({
      id: n.id,
      type: n.data.type,
      enabled: true,
      ...n.data
    }));

    const processors = nodes.filter(n => n.type === 'processorNode').map(n => ({
      id: n.id,
      type: n.data.language,
      parallel: n.data.parallel || false,
      timeout: n.data.timeout || 5000,
      retry: n.data.retry || 1,
      dependencies: edges.filter(e => e.target === n.id).map(e => e.source),
      ...n.data
    }));

    const outputs = nodes.filter(n => n.type === 'outputNode').map(n => ({
      id: n.id,
      type: n.data.type,
      ...n.data
    }));

    return `name: "${name}"
version: "1.0.0"
description: "Generated pipeline configuration"

triggers:
${triggers.map(t => `  - id: ${t.id}
    type: ${t.type}
    enabled: ${t.enabled}
    ${Object.entries(t).filter(([k]) => !['id', 'type', 'enabled', 'label'].includes(k))
      .map(([k, v]) => `${k}: ${typeof v === 'string' ? `"${v}"` : v}`).join('\n    ')}`).join('\n')}

processors:
${processors.map(p => `  - id: ${p.id}
    type: ${p.type}
    parallel: ${p.parallel}
    timeout: ${p.timeout}
    retry: ${p.retry}
    dependencies: [${p.dependencies.map(d => `"${d}"`).join(', ')}]
    ${Object.entries(p).filter(([k]) => !['id', 'type', 'parallel', 'timeout', 'retry', 'dependencies', 'label', 'language'].includes(k))
      .map(([k, v]) => `${k}: ${typeof v === 'string' ? `"${v}"` : JSON.stringify(v)}`).join('\n    ')}`).join('\n')}

outputs:
${outputs.map(o => `  - id: ${o.id}
    type: ${o.type}
    ${Object.entries(o).filter(([k]) => !['id', 'type', 'label'].includes(k))
      .map(([k, v]) => `${k}: ${Array.isArray(v) ? `[${v.map(x => `"${x}"`).join(', ')}]` : typeof v === 'string' ? `"${v}"` : v}`).join('\n    ')}`).join('\n')}

settings:
  performance:
    max_concurrent: 10
    buffer_size: 1000
  monitoring:
    enabled: true
  security:
    require_auth: false`;
  };

  return (
    <div className="h-screen flex bg-white">
      <ComponentPalette onAddNode={onAddNode} />

      <div className="flex-1 flex flex-col">
        {/* Toolbar */}
        <div className="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-4">
          <div className="flex items-center gap-4">
            <input
              type="text"
              value={pipelineName}
              onChange={(e) => setPipelineName(e.target.value)}
              className="text-lg font-semibold bg-transparent border-none focus:outline-none focus:ring-0 text-gray-800"
            />
            <span className="text-sm text-gray-500">Visual Pipeline Editor</span>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={onRunPipeline}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition-colors ${
                isRunning
                  ? 'bg-red-500 hover:bg-red-600 text-white'
                  : 'bg-green-500 hover:bg-green-600 text-white'
              }`}
            >
              {isRunning ? <Pause size={16} /> : <Play size={16} />}
              {isRunning ? 'Stop' : 'Run'}
            </button>

            <button
              onClick={onSavePipeline}
              className="flex items-center gap-2 px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded-lg font-medium transition-colors"
            >
              <Download size={16} />
              Export YAML
            </button>
          </div>
        </div>

        {/* React Flow Canvas */}
        <div className="flex-1">
          <ReactFlow
            nodes={nodes}
            edges={edges}
            onNodesChange={onNodesChange}
            onEdgesChange={onEdgesChange}
            onConnect={onConnect}
            onNodeClick={onNodeClick}
            nodeTypes={nodeTypes}
            fitView
            className="bg-gray-50"
          >
            <Controls />
            <MiniMap />
            <Background variant="dots" gap={12} size={1} />

            <Panel position="top-center">
              <div className="bg-white px-4 py-2 rounded-lg shadow-lg border border-gray-200">
                <div className="flex items-center gap-4 text-sm">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 bg-blue-500 rounded-full"></div>
                    <span>Triggers: {nodes.filter(n => n.type === 'triggerNode').length}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 bg-green-500 rounded-full"></div>
                    <span>Processors: {nodes.filter(n => n.type === 'processorNode').length}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 bg-purple-500 rounded-full"></div>
                    <span>Outputs: {nodes.filter(n => n.type === 'outputNode').length}</span>
                  </div>
                </div>
              </div>
            </Panel>
          </ReactFlow>
        </div>
      </div>

      <PropertiesPanel selectedNode={selectedNode} onUpdateNode={onUpdateNode} />
    </div>
  );
};

export default DialogChainVisualEditor;
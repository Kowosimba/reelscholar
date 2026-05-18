enum NodeKind { concept, process, principle, example, tool, topic }

extension NodeKindMeta on NodeKind {
  String get label => switch (this) {
        NodeKind.concept => 'Concept',
        NodeKind.process => 'Process',
        NodeKind.principle => 'Principle',
        NodeKind.example => 'Example',
        NodeKind.tool => 'Tool',
        NodeKind.topic => 'Topic',
      };

  static NodeKind fromString(String s) => switch (s) {
        'process' => NodeKind.process,
        'principle' => NodeKind.principle,
        'example' => NodeKind.example,
        'tool' => NodeKind.tool,
        'topic' => NodeKind.topic,
        _ => NodeKind.concept,
      };
}

enum EdgeRelation {
  isA,
  partOf,
  causes,
  dependsOn,
  contrastsWith,
  exampleOf,
  appliesTo,
  precedes,
}

extension EdgeRelationMeta on EdgeRelation {
  String get label => switch (this) {
        EdgeRelation.isA => 'is a',
        EdgeRelation.partOf => 'part of',
        EdgeRelation.causes => 'causes',
        EdgeRelation.dependsOn => 'depends on',
        EdgeRelation.contrastsWith => 'contrasts with',
        EdgeRelation.exampleOf => 'example of',
        EdgeRelation.appliesTo => 'applies to',
        EdgeRelation.precedes => 'precedes',
      };

  static EdgeRelation fromString(String s) => switch (s) {
        'is_a' => EdgeRelation.isA,
        'part_of' => EdgeRelation.partOf,
        'causes' => EdgeRelation.causes,
        'depends_on' => EdgeRelation.dependsOn,
        'contrasts_with' => EdgeRelation.contrastsWith,
        'example_of' => EdgeRelation.exampleOf,
        'precedes' => EdgeRelation.precedes,
        _ => EdgeRelation.appliesTo,
      };
}

class ConceptNode {
  final String id;
  final String label;
  final NodeKind kind;
  final String description;
  final int topicIndex;
  final int importance; // 1-3

  ConceptNode({
    required this.id,
    required this.label,
    required this.kind,
    required this.description,
    required this.topicIndex,
    required this.importance,
  });

  factory ConceptNode.fromJson(Map<String, dynamic> j) => ConceptNode(
        id: j['id']?.toString() ?? '',
        label: j['label']?.toString() ?? '',
        kind: NodeKindMeta.fromString(j['kind']?.toString() ?? 'concept'),
        description: j['description']?.toString() ?? '',
        topicIndex: (j['topic_index'] as num?)?.toInt() ?? -1,
        importance: (j['importance'] as num?)?.toInt() ?? 2,
      );
}

class ConceptEdge {
  final String from;
  final String to;
  final EdgeRelation relation;
  final String label;

  ConceptEdge({
    required this.from,
    required this.to,
    required this.relation,
    required this.label,
  });

  factory ConceptEdge.fromJson(Map<String, dynamic> j) => ConceptEdge(
        from: j['from']?.toString() ?? '',
        to: j['to']?.toString() ?? '',
        relation: EdgeRelationMeta.fromString(
            j['relation']?.toString() ?? 'applies_to'),
        label: j['label']?.toString() ?? '',
      );
}

class ConceptMap {
  final String title;
  final String summary;
  final List<ConceptNode> nodes;
  final List<ConceptEdge> edges;

  ConceptMap({
    required this.title,
    required this.summary,
    required this.nodes,
    required this.edges,
  });

  factory ConceptMap.fromJson(Map<String, dynamic> j) => ConceptMap(
        title: j['title']?.toString() ?? '',
        summary: j['summary']?.toString() ?? '',
        nodes: (j['nodes'] as List?)
                ?.map((n) => ConceptNode.fromJson(n as Map<String, dynamic>))
                .toList() ??
            [],
        edges: (j['edges'] as List?)
                ?.map((e) => ConceptEdge.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class SystemsProfile {
  final ProfileIdentity identity;
  final List<String> targetRoles;
  final CorporateEntities corporateEntities;
  final ContactAndSocials contactAndSocials;
  final TechnicalArchitectureStack technicalArchitectureStack;
  final List<ProprietaryFramework> proprietaryFrameworks;
  final List<ShippedProject> shippedProvenMatrix;
  final SdlcParadigms sdlcParadigms;

  const SystemsProfile({
    required this.identity,
    required this.targetRoles,
    required this.corporateEntities,
    required this.contactAndSocials,
    required this.technicalArchitectureStack,
    required this.proprietaryFrameworks,
    required this.shippedProvenMatrix,
    required this.sdlcParadigms,
  });
}

class ProfileIdentity {
  final String name;
  final String professionalTitle;
  final int yearsOfExperience;
  final String currentLocation;
  final String corePhilosophy;

  const ProfileIdentity({
    required this.name,
    required this.professionalTitle,
    required this.yearsOfExperience,
    required this.currentLocation,
    required this.corePhilosophy,
  });
}

class CorporateEntities {
  final String designStudio;
  final String parentEntity;
  final String holdingCompany;

  const CorporateEntities({
    required this.designStudio,
    required this.parentEntity,
    required this.holdingCompany,
  });
}

class ContactAndSocials {
  final String email;
  final String phone;
  final String linkedin;
  final String github;
  final String digitalHq;

  const ContactAndSocials({
    required this.email,
    required this.phone,
    required this.linkedin,
    required this.github,
    required this.digitalHq,
  });
}

class TechnicalArchitectureStack {
  final String frontendFramework;
  final String language;
  final String heavyLogicExecution;
  final String multithreadingInfrastructure;
  final String backendEcosystem;

  const TechnicalArchitectureStack({
    required this.frontendFramework,
    required this.language,
    required this.heavyLogicExecution,
    required this.multithreadingInfrastructure,
    required this.backendEcosystem,
  });
}

class ProprietaryFramework {
  final String id;
  final String name;
  final List<String> components;
  final String description;

  const ProprietaryFramework({
    required this.id,
    required this.name,
    required this.components,
    required this.description,
  });
}

class ShippedProject {
  final String title;
  final String type;
  final String platform;
  final String coreEngineering;

  const ShippedProject({
    required this.title,
    required this.type,
    required this.platform,
    required this.coreEngineering,
  });
}

class SdlcParadigms {
  final String softwareMethodology;
  final String hardwareAugmentedSdlc;

  const SdlcParadigms({
    required this.softwareMethodology,
    required this.hardwareAugmentedSdlc,
  });
}

class SystemsProfileSeed {
  static const SystemsProfile systemsProfileArturoRobertoGarcia = SystemsProfile(
    identity: ProfileIdentity(
      name: 'Arturo Roberto Garcia',
      professionalTitle: 'Consultant & A.I. Product Designer',
      yearsOfExperience: 13,
      currentLocation: 'Lacey, Washington, United States',
      corePhilosophy:
          'Applying a deeply ingrained, highly deterministic engineering philosophy to chaotic algorithmic mediums. '
          'Transforming complex backend execution and multi-agent AI networks into usable, coherent, and predictable human experiences.',
    ),
    targetRoles: [
      'Consultant / Principal Product Designer (DevX & AI Systems Architecture)',
      'A.I. Product Architect / Systems Designer',
      'Senior Product Designer (Enterprise B2B SaaS & API-First Ecosystems)',
    ],
    corporateEntities: CorporateEntities(
      designStudio: 'Form & Flow Design Studio',
      parentEntity: 'Parallel Paradigm LLC',
      holdingCompany: 'Paradigm Foundry',
    ),
    contactAndSocials: ContactAndSocials(
      email: 'arrgarci7@gmail.com',
      phone: '+1 (360) XXX-XXXX',
      linkedin: 'https://www.linkedin.com/in/your-profile-url',
      github: 'https://github.com/your-username',
      digitalHq: 'https://formandflow.design',
    ),
    technicalArchitectureStack: TechnicalArchitectureStack(
      frontendFramework: 'Flutter',
      language: 'Dart',
      heavyLogicExecution: 'WebAssembly (WASM)',
      multithreadingInfrastructure: 'Web Workers / Isolates',
      backendEcosystem: 'Supabase / Firebase (Realtime Stream Providers)',
    ),
    proprietaryFrameworks: [
      ProprietaryFramework(
        id: 'metrics',
        name: 'METRICS',
        components: ['Magnitude', 'Efficiency', 'Threshold', 'Indexes', 'Ratios'],
        description:
            'A mathematical validation engine that applies deterministic formulas to user experience metrics and algorithmic system behaviors, bypassing subjective look-and-feel evaluations.',
      ),
      ProprietaryFramework(
        id: 'gemsg',
        name: 'GEMSG Matrix',
        components: ['Growth', 'Engagement', 'Monetization', 'Support', 'Governance/Security'],
        description: 'A multidimensional strategic framework used to map core enterprise business drivers directly into software layout logic and backend functionality.',
      ),
      ProprietaryFramework(
        id: 'universal_bios',
        name: 'Universal BIOS',
        components: ['Human-to-Machine Intent Translators', 'Deterministic Output Guardrails'],
        description:
            'An architectural interaction model designed to govern autonomous, multi-agent networks, serving as the interface standard that renders complex blackboxes completely safe and traceable.',
      ),
    ],
    shippedProvenMatrix: [
      ShippedProject(
        title: 'TipZero',
        type: 'Utility / Fintech Architecture',
        platform: 'iOS App Store',
        coreEngineering: 'Rigid, zero-margin state management and high-precision calculations governed by strict local primitives.',
      ),
      ShippedProject(
        title: 'Bridge Bound Connect',
        type: 'Educational Utility / Platform Ecosystem',
        platform: 'iOS App Store',
        coreEngineering: 'Complex structural rule engines tightly integrated with deterministic human feedback loops.',
      ),
      ShippedProject(
        title: 'Passing Lane',
        type: 'High-Performance Interactive Simulation',
        platform: 'iOS App Store',
        coreEngineering: 'Built on top of localized calculation engines and rapid-state rendering logic pipelines.',
      ),
      ShippedProject(
        title: 'Human in the Loop',
        type: 'Experimental System / Interactive Mechanic',
        platform: 'Portfolio Showcase',
        coreEngineering: 'An exploration of autonomous algorithmic parameters bound tightly by explicit manual intervention gates.',
      ),
    ],
    sdlcParadigms: SdlcParadigms(
      softwareMethodology:
          'High-velocity systems-driven sprints, automated compilation tracking, and strict separation of presentation layers from computational logic.',
      hardwareAugmentedSdlc:
          'Cross-disciplinary systems architecture applying software engineering principles (modularity, precision tolerances, deterministic inputs) to physical structural frameworks, structural joinery, and sustainable permaculture design.',
    ),
  );
}

using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

/// <summary>Runtime-built Astana-inspired prototype scene and mobile controls.</summary>
public sealed class KokboriSceneBootstrap : MonoBehaviour
{
    private Transform player;
    private CharacterController character;
    private Camera gameCamera;
    private Vector2 moveInput;
    private float verticalSpeed;
    private float vehicleThrottle;
    private RectTransform stickKnob;
    private KokboriVehicleController vehicle;
    private const float MoveSpeed = 4.5f;

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
    private static void StartPrototype()
    {
        if (FindObjectOfType<KokboriSceneBootstrap>() == null)
            new GameObject("KOKBORI Runtime Bootstrap").AddComponent<KokboriSceneBootstrap>();
    }

    private void Start()
    {
        Application.targetFrameRate = 60;
        BuildWorld();
        BuildPlayer();
        BuildCamera();
        vehicle = KokboriVehicleController.Create(new Vector3(3, 0, -4));
        BuildTouchUI();
    }

    private void Update()
    {
        if (character == null) return;
        if (vehicle != null && vehicle.IsDriving)
        {
            vehicle.SetControls(vehicleThrottle, moveInput.x);
            vehicle.Tick(Time.deltaTime);
            return;
        }

        Vector2 input = moveInput;
#if UNITY_EDITOR || UNITY_STANDALONE
        if (input.sqrMagnitude < 0.01f)
            input = new Vector2(Input.GetAxisRaw("Horizontal"), Input.GetAxisRaw("Vertical"));
#endif
        Vector3 forward = gameCamera.transform.forward;
        Vector3 right = gameCamera.transform.right;
        forward.y = 0; right.y = 0;
        forward.Normalize(); right.Normalize();
        Vector3 direction = Vector3.ClampMagnitude(forward * input.y + right * input.x, 1f);
        if (direction.sqrMagnitude > 0.001f)
            player.rotation = Quaternion.Slerp(player.rotation, Quaternion.LookRotation(direction), 12f * Time.deltaTime);
        if (character.isGrounded && verticalSpeed < 0) verticalSpeed = -2f;
        verticalSpeed += -20f * Time.deltaTime;
        character.Move((direction * MoveSpeed + Vector3.up * verticalSpeed) * Time.deltaTime);
    }

    private void LateUpdate()
    {
        if (player == null || gameCamera == null || (vehicle != null && vehicle.IsDriving)) return;
        Vector3 desired = player.position + player.rotation * new Vector3(0, 3.8f, -6.2f);
        gameCamera.transform.position = Vector3.Lerp(gameCamera.transform.position, desired, 8f * Time.deltaTime);
        gameCamera.transform.LookAt(player.position + Vector3.up * 1.35f);
    }

    private void BuildWorld()
    {
        RenderSettings.ambientLight = new Color(0.62f, 0.66f, 0.72f);
        CreateBlock("Terrain", new Vector3(0, -0.55f, 0), new Vector3(220, 1, 220), new Color(0.34f, 0.39f, 0.34f));
        CreateBlock("Central Avenue", new Vector3(0, -0.015f, 0), new Vector3(16, 0.08f, 175), new Color(0.12f, 0.13f, 0.15f));
        CreateBlock("Cross Avenue", new Vector3(0, 0.015f, 8), new Vector3(175, 0.08f, 12), new Color(0.12f, 0.13f, 0.15f));
        CreateBlock("River Road", new Vector3(0, 0.015f, 42), new Vector3(175, 0.08f, 9), new Color(0.13f, 0.14f, 0.16f));
        CreateBlock("Ishim Embankment", new Vector3(0, -0.18f, 51), new Vector3(175, 0.18f, 7), new Color(0.58f, 0.55f, 0.46f));
        CreateBlock("Ishim River", new Vector3(0, -0.35f, 61), new Vector3(175, 0.1f, 13), new Color(0.12f, 0.35f, 0.48f));

        // Dashed lane markings along the central avenue.
        for (int z = -78; z <= 78; z += 9)
            CreateBlock("Lane Marking", new Vector3(0, 0.045f, z), new Vector3(0.16f, 0.025f, 4.2f), new Color(0.88f, 0.84f, 0.68f));
        for (int x = -78; x <= 78; x += 9)
            CreateBlock("Cross Lane Marking", new Vector3(x, 0.06f, 8), new Vector3(4.2f, 0.025f, 0.14f), new Color(0.88f, 0.84f, 0.68f));

        // Residential blocks, courtyards, storefronts and repeated windows.
        for (int i = 0; i < 10; i++)
        {
            float side = i % 2 == 0 ? -1f : 1f;
            float x = side * (19 + (i / 2) * 16);
            float z = -62 + i * 13;
            float height = 10 + (i % 3) * 4;
            CreateBlock("Residential Building " + i, new Vector3(x, height * 0.5f, z),
                new Vector3(12, height, 11), i % 2 == 0 ? new Color(0.67f, 0.62f, 0.54f) : new Color(0.54f, 0.61f, 0.65f));
            CreateBlock("Courtyard " + i, new Vector3(x - side * 8, 0.04f, z + 5),
                new Vector3(7, 0.12f, 8), new Color(0.28f, 0.42f, 0.27f));
            for (int floor = 1; floor < Mathf.Max(2, (int)(height / 3)); floor++)
            for (int window = -1; window <= 1; window++)
                CreateBlock("Facade Window", new Vector3(x + window * 3.2f, floor * 2.7f, z - 5.56f),
                    new Vector3(1.45f, 1.15f, 0.08f), new Color(0.2f, 0.38f, 0.48f));
        }

        // Street lights along the main road.
        for (int z = -70; z <= 70; z += 20)
        for (int side = -1; side <= 1; side += 2)
        {
            Vector3 pos = new Vector3(side * 10.5f, 0, z);
            CreateBlock("Street Lamp Pole", pos + Vector3.up * 3, new Vector3(0.16f, 6, 0.16f), new Color(0.18f, 0.2f, 0.22f));
            CreateBlock("Street Lamp Arm", pos + new Vector3(-side * 0.8f, 5.8f, 0), new Vector3(1.8f, 0.12f, 0.16f), new Color(0.18f, 0.2f, 0.22f));
            CreateBlock("Lamp", pos + new Vector3(-side * 1.5f, 5.7f, 0), new Vector3(0.65f, 0.16f, 0.45f), new Color(0.95f, 0.86f, 0.58f));
        }

        // Low-poly trees in small green areas.
        for (int i = 0; i < 18; i++)
        {
            float x = (i % 2 == 0 ? -1 : 1) * (14 + (i % 4) * 7);
            float z = -68 + i * 8;
            CreateBlock("Tree Trunk", new Vector3(x, 1.1f, z), new Vector3(0.45f, 2.2f, 0.45f), new Color(0.32f, 0.22f, 0.13f));
            CreateBlock("Tree Crown", new Vector3(x, 2.8f, z), new Vector3(2.2f, 2.4f, 2.2f), new Color(0.16f, 0.34f, 0.19f));
        }

        // Original landmark silhouette, not a replica of a protected game asset.
        CreateBlock("City Landmark Base", new Vector3(0, 2, -27), new Vector3(5, 4, 5), new Color(0.72f, 0.62f, 0.34f));
        CreateBlock("City Landmark Shaft", new Vector3(0, 8, -27), new Vector3(1.2f, 9, 1.2f), new Color(0.78f, 0.7f, 0.48f));
        CreateBlock("City Landmark Crown", new Vector3(0, 13, -27), new Vector3(4, 1.2f, 4), new Color(0.82f, 0.7f, 0.34f));

        var lightObject = new GameObject("Sun");
        var sun = lightObject.AddComponent<Light>();
        sun.type = LightType.Directional;
        sun.intensity = 1.15f;
        lightObject.transform.rotation = Quaternion.Euler(50, -30, 0);
    }

    private void BuildPlayer()
    {
        var go = GameObject.CreatePrimitive(PrimitiveType.Capsule);
        go.name = "KOKBORI Player";
        go.transform.position = new Vector3(0, 1.1f, -5);
        go.GetComponent<Renderer>().material = MakeMaterial(new Color(0.12f, 0.32f, 0.62f));
        Destroy(go.GetComponent<CapsuleCollider>());
        character = go.AddComponent<CharacterController>();
        character.height = 1.8f;
        character.radius = 0.38f;
        character.center = new Vector3(0, 0.9f, 0);
        player = go.transform;
    }

    private void BuildCamera()
    {
        var cameraObject = new GameObject("KOKBORI Camera");
        gameCamera = cameraObject.AddComponent<Camera>();
        cameraObject.tag = "MainCamera";
        gameCamera.fieldOfView = 65;
        cameraObject.transform.position = player.position + new Vector3(0, 4, -6);
        cameraObject.transform.LookAt(player.position + Vector3.up);
        cameraObject.AddComponent<AudioListener>();
    }

    private void BuildTouchUI()
    {
        var canvasObject = new GameObject("Mobile HUD");
        var canvas = canvasObject.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        canvasObject.AddComponent<CanvasScaler>().uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        canvasObject.AddComponent<GraphicRaycaster>();
        if (FindObjectOfType<EventSystem>() == null)
        {
            var eventObject = new GameObject("EventSystem");
            eventObject.AddComponent<EventSystem>();
            eventObject.AddComponent<StandaloneInputModule>();
        }

        var stickBase = MakeUIRect("Joystick Base", canvas.transform, Vector2.zero, Vector2.zero,
            new Vector2(150, 150), new Vector2(110, 110));
        stickBase.gameObject.AddComponent<Image>().color = new Color(0.05f, 0.07f, 0.1f, 0.42f);
        stickBase.gameObject.AddComponent<JoystickPointer>().Initialize(this);
        stickKnob = MakeUIRect("Joystick Knob", stickBase, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f),
            new Vector2(80, 80), Vector2.zero);
        stickKnob.gameObject.AddComponent<Image>().color = new Color(0.88f, 0.9f, 0.94f, 0.75f);

        var title = MakeUIRect("KOKBORI Title", canvas.transform, new Vector2(0.5f, 1), new Vector2(0.5f, 1),
            new Vector2(440, 55), new Vector2(0, -35)).gameObject.AddComponent<Text>();
        title.text = "KOKBORI RP  •  ASTANA TEST BUILD";
        title.alignment = TextAnchor.MiddleCenter;
        title.font = Resources.GetBuiltinResource<Font>("Arial.ttf");
        title.fontSize = 22;
        title.color = Color.white;

        MakeActionButton("ENTER / EXIT", canvas.transform, new Vector2(1, 0), new Vector2(1, 0),
            new Vector2(170, 64), new Vector2(-115, 105), () => vehicle.ToggleDrive(player, character, gameCamera));
        MakeHoldButton("GAS", canvas.transform, new Vector2(1, 0), new Vector2(1, 0),
            new Vector2(112, 78), new Vector2(-105, 215), 1f);
        MakeHoldButton("BRAKE", canvas.transform, new Vector2(1, 0), new Vector2(1, 0),
            new Vector2(112, 78), new Vector2(-235, 125), -1f);
    }

    private void MakeActionButton(string captionText, Transform parent, Vector2 anchorMin, Vector2 anchorMax,
        Vector2 size, Vector2 position, UnityEngine.Events.UnityAction action)
    {
        var rect = MakeUIRect(captionText, parent, anchorMin, anchorMax, size, position);
        rect.gameObject.AddComponent<Image>().color = new Color(0.05f, 0.08f, 0.12f, 0.72f);
        rect.gameObject.AddComponent<Button>().onClick.AddListener(action);
        AddCaption(rect, captionText);
    }

    private void MakeHoldButton(string captionText, Transform parent, Vector2 anchorMin, Vector2 anchorMax,
        Vector2 size, Vector2 position, float value)
    {
        var rect = MakeUIRect(captionText, parent, anchorMin, anchorMax, size, position);
        rect.gameObject.AddComponent<Image>().color = new Color(0.05f, 0.08f, 0.12f, 0.72f);
        rect.gameObject.AddComponent<KokboriHoldButton>().Initialize(() => vehicleThrottle = value, () => vehicleThrottle = 0);
        AddCaption(rect, captionText);
    }

    private static void AddCaption(RectTransform parent, string captionText)
    {
        var label = MakeUIRect("Label", parent, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero).gameObject.AddComponent<Text>();
        label.font = Resources.GetBuiltinResource<Font>("Arial.ttf");
        label.text = captionText;
        label.alignment = TextAnchor.MiddleCenter;
        label.fontSize = 16;
        label.color = Color.white;
    }

    private void SetJoystick(Vector2 value)
    {
        moveInput = Vector2.ClampMagnitude(value, 1f);
        if (stickKnob != null) stickKnob.anchoredPosition = moveInput * 35f;
    }

    private static RectTransform MakeUIRect(string name, Transform parent, Vector2 anchorMin,
        Vector2 anchorMax, Vector2 size, Vector2 position)
    {
        var go = new GameObject(name, typeof(RectTransform));
        go.transform.SetParent(parent, false);
        var rect = go.GetComponent<RectTransform>();
        rect.anchorMin = anchorMin; rect.anchorMax = anchorMax;
        rect.sizeDelta = size; rect.anchoredPosition = position;
        return rect;
    }

    private static void CreateBlock(string name, Vector3 position, Vector3 scale, Color color)
    {
        var block = GameObject.CreatePrimitive(PrimitiveType.Cube);
        block.name = name;
        block.transform.position = position;
        block.transform.localScale = scale;
        block.GetComponent<Renderer>().material = MakeMaterial(color);
    }

    private static Material MakeMaterial(Color color)
    {
        Shader shader = Shader.Find("Universal Render Pipeline/Lit");
        if (shader == null) shader = Shader.Find("Standard");
        var material = new Material(shader);
        material.color = color;
        return material;
    }

    public sealed class JoystickPointer : MonoBehaviour, IPointerDownHandler, IDragHandler, IPointerUpHandler
    {
        private KokboriSceneBootstrap owner;
        public void Initialize(KokboriSceneBootstrap bootstrap) => owner = bootstrap;
        public void OnPointerDown(PointerEventData eventData) => OnDrag(eventData);
        public void OnDrag(PointerEventData eventData)
        {
            var rect = transform as RectTransform;
            if (RectTransformUtility.ScreenPointToLocalPointInRectangle(rect, eventData.position,
                eventData.pressEventCamera, out Vector2 point))
            {
                Vector2 half = rect.rect.size * 0.5f;
                owner?.SetJoystick(new Vector2(half.x > 0 ? point.x / half.x : 0, half.y > 0 ? point.y / half.y : 0));
            }
        }
        public void OnPointerUp(PointerEventData eventData) => owner?.SetJoystick(Vector2.zero);
    }
}
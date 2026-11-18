using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

/// <summary>
/// Builds a playable greybox scene at runtime: player, follow camera,
/// Astana-inspired blockout and a touch joystick. No external assets required.
/// </summary>
public sealed class KokboriSceneBootstrap : MonoBehaviour
{
    private Transform player;
    private Vector2 moveInput;
    private float verticalSpeed;
    private CharacterController character;
    private Camera gameCamera;
    private RectTransform stickBase;
    private RectTransform stickKnob;
    private const float MoveSpeed = 4.5f;\n    private KokboriVehicleController vehicle;\n    private float vehicleThrottle;

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
        BuildTouchUI();
    }

    private void Update()
    {
        if (character == null) return;
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
        CreateBlock("Ground", new Vector3(0, -0.55f, 0), new Vector3(180, 1, 180), new Color(0.34f, 0.39f, 0.34f));
        CreateBlock("Main Avenue", new Vector3(0, -0.02f, 0), new Vector3(12, 0.08f, 150), new Color(0.12f, 0.13f, 0.15f));
        CreateBlock("Cross Street", new Vector3(0, 0.02f, 8), new Vector3(150, 0.08f, 10), new Color(0.12f, 0.13f, 0.15f));
        CreateBlock("River Embankment", new Vector3(0, -0.25f, 42), new Vector3(150, 0.15f, 9), new Color(0.58f, 0.55f, 0.46f));
        CreateBlock("Ishim River", new Vector3(0, -0.35f, 53), new Vector3(150, 0.1f, 12), new Color(0.12f, 0.35f, 0.48f));

        for (int i = 0; i < 7; i++)
        {
            float x = (i % 2 == 0 ? -1 : 1) * (18 + (i / 2) * 17);
            float z = -45 + i * 15;
            float height = 9 + (i % 3) * 5;
            CreateBlock("Residential Block " + (i + 1), new Vector3(x, height * 0.5f, z),
                new Vector3(13, height, 12), new Color(0.66f, 0.62f, 0.54f));
            CreateBlock("Courtyard", new Vector3(x * 0.55f, 0.05f, z + 8),
                new Vector3(8, 0.1f, 5), new Color(0.28f, 0.42f, 0.27f));
        }

        // A simple landmark silhouette, deliberately original and low-poly.
        CreateBlock("Landmark Base", new Vector3(0, 2, -25), new Vector3(5, 4, 5), new Color(0.72f, 0.62f, 0.34f));
        CreateBlock("Landmark Shaft", new Vector3(0, 8, -25), new Vector3(1.2f, 9, 1.2f), new Color(0.78f, 0.7f, 0.48f));
        CreateBlock("Landmark Crown", new Vector3(0, 13, -25), new Vector3(4, 1.2f, 4), new Color(0.82f, 0.7f, 0.34f));

        var lightObject = new GameObject("Sun");
        var light = lightObject.AddComponent<Light>();
        light.type = LightType.Directional;
        light.intensity = 1.15f;
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

        stickBase = MakeUIRect("Joystick Base", canvas.transform, new Vector2(0, 0), new Vector2(0, 0),
            new Vector2(150, 150), new Vector2(110, 110));
        stickBase.gameObject.AddComponent<Image>().color = new Color(0.05f, 0.07f, 0.1f, 0.42f);
        var handler = stickBase.gameObject.AddComponent<JoystickPointer>();
        handler.Initialize(this);
        stickKnob = MakeUIRect("Joystick Knob", stickBase, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f),
            new Vector2(80, 80), Vector2.zero);
        stickKnob.gameObject.AddComponent<Image>().color = new Color(0.88f, 0.9f, 0.94f, 0.75f);

        var labelRect = MakeUIRect("KOKBORI Title", canvas.transform, new Vector2(0.5f, 1), new Vector2(0.5f, 1),
            new Vector2(440, 55), new Vector2(0, -35));
        var label = labelRect.gameObject.AddComponent<Text>();
        label.text = "KOKBORI RP  •  ASTANA TEST BUILD";
        label.alignment = TextAnchor.MiddleCenter;
        label.font = Resources.GetBuiltinResource<Font>("Arial.ttf");
        label.fontSize = 22;
        label.color = Color.white;
    }

    private void SetThrottle(float value) => vehicleThrottle = value;

    private void MakeActionButton(string textValue, Transform parent, Vector2 anchorMin,
        Vector2 anchorMax, Vector2 size, Vector2 position, UnityEngine.Events.UnityAction action)
    {
        var rect = MakeUIRect(textValue, parent, anchorMin, anchorMax, size, position);
        var image = rect.gameObject.AddComponent<Image>();
        image.color = new Color(0.05f, 0.08f, 0.12f, 0.72f);
        var button = rect.gameObject.AddComponent<Button>();
        button.onClick.AddListener(action);
        var caption = MakeUIRect("Label", rect, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
        var label = caption.gameObject.AddComponent<Text>();
        label.font = Resources.GetBuiltinResource<Font>("Arial.ttf");
        label.text = textValue;
        label.alignment = TextAnchor.MiddleCenter;
        label.fontSize = 16;
        label.color = Color.white;
    }

    private void MakeHoldButton(string textValue, Transform parent, Vector2 anchorMin,
        Vector2 anchorMax, Vector2 size, Vector2 position, float value)
    {
        var rect = MakeUIRect(textValue, parent, anchorMin, anchorMax, size, position);
        rect.gameObject.AddComponent<Image>().color = new Color(0.05f, 0.08f, 0.12f, 0.72f);
        var hold = rect.gameObject.AddComponent<KokboriHoldButton>();
        hold.Initialize(() => SetThrottle(value), () => SetThrottle(0));
        var caption = MakeUIRect("Label", rect, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
        var label = caption.gameObject.AddComponent<Text>();
        label.font = Resources.GetBuiltinResource<Font>("Arial.ttf");
        label.text = textValue;
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
            RectTransform rect = transform as RectTransform;
            if (RectTransformUtility.ScreenPointToLocalPointInRectangle(rect, eventData.position,
                    eventData.pressEventCamera, out Vector2 point))
            {
                Vector2 half = rect.rect.size * 0.5f;
                owner?.SetJoystick(new Vector2(half.x > 0 ? point.x / half.x : 0,
                    half.y > 0 ? point.y / half.y : 0));
            }
        }
        public void OnPointerUp(PointerEventData eventData) => owner?.SetJoystick(Vector2.zero);
    }
}

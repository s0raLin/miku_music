use global_hotkey::{
    hotkey::{Code, HotKey, Modifiers},
    GlobalHotKeyEvent, GlobalHotKeyManager,
};
use std::sync::OnceLock;
use std::thread;

use crate::frb_generated::StreamSink;

// 使用 OnceLock 确保全局只有一个热键管理器
static HOTKEY_MANAGER: OnceLock<GlobalHotKeyManager> = OnceLock::new();


pub fn init_native_hotkeys(sink: StreamSink<String>) -> Result<(), String> {

    // 克隆两份 sink 分别送给不同的热键回调
    let sink_toggle = sink.clone();
    let sink_next = sink.clone();
    let sink_prev = sink.clone();

    init_rust_hotkeys(
        Box::new(move || {
            let _ = sink_toggle.add("toggle_play".to_string());
        }),
        Box::new(move || {
            let _ = sink_next.add("next_track".to_string());
        }),
        Box::new(move || {
            let _ = sink_prev.add("prev_track".to_string());
        }),
    );

    Ok(())
}

/// 初始化全局热键（由 Dart 端在启动时调用一次）
fn init_rust_hotkeys(
    // 传入两个回调，当热键触发时通知播放器内核
    on_toggle_play: Box<dyn Fn() + Send + Sync + 'static>,
    on_next_track: Box<dyn Fn() + Send + Sync + 'static>,
    on_prev_track: Box<dyn Fn() + Send + Sync + 'static>,
) {
    // 1. 获取或初始化全局管理器
    let manager = HOTKEY_MANAGER.get_or_init(|| GlobalHotKeyManager::new().unwrap());

    // 2. 定义组合键
    // 播放/暂停: Ctrl + Alt + Space
    let hotkey_toggle = HotKey::new(Some(Modifiers::CONTROL | Modifiers::ALT), Code::Space);
    // 下一首: Ctrl + Alt + ArrowRight
    let hotkey_next = HotKey::new(Some(Modifiers::CONTROL | Modifiers::ALT), Code::ArrowRight);
    // 上一首: Ctrl + Alt + ArrowLeft
    let hotkey_prev = HotKey::new(Some(Modifiers::CONTROL | Modifiers::ALT), Code::ArrowLeft);

    // 拿到它们在库内部真正唯一的那个 ID (对应里面的数字)
    let id_toggle = hotkey_toggle.id();
    let id_next = hotkey_next.id();
    let id_prev = hotkey_prev.id();

    // 3. 向操作系统注册
    manager.register(hotkey_toggle).unwrap();
    manager.register(hotkey_next).unwrap();
    manager.register(hotkey_prev).unwrap();

    // 4. 建立映射关系，放到单独的后台线程去轮询事件，避免阻塞主线程
    // 4. 建立映射关系，放到单独的后台线程去轮询事件
    thread::spawn(move || {
        let receiver = GlobalHotKeyEvent::receiver();
        loop {
            // 直接使用标准的 .recv() 阻塞接收事件
            if let Ok(event) = receiver.recv() {
                if event.state == global_hotkey::HotKeyState::Pressed {
                    match event.id {
                        id if id == id_toggle => {
                            // println!("Rust 捕获到：播放/暂停");
                            on_toggle_play();
                        }
                        id if id == id_next => {
                            // println!("Rust 捕获到：下一首");
                            on_next_track();
                        }
                        id if id == id_prev => {
                            // println!("Rust捕获到: 上一首");
                            on_prev_track();
                        }
                        _ => {}
                    }
                }
            }
        }
    });
}


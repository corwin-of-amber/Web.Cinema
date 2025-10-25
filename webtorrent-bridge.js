

export default async function wt() {
    return (await import('webtorrent')).default;
}
